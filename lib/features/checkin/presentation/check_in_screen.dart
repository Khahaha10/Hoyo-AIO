import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/app_snackbar.dart';
import 'package:hoyo_aio/core/design_system/components/game_switcher_chip.dart';
import 'package:hoyo_aio/core/design_system/components/skeleton.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/game_labels.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_month.dart';
import 'package:hoyo_aio/features/checkin/presentation/check_in_format.dart';
import 'package:hoyo_aio/features/checkin/presentation/providers/check_in_provider.dart';
import 'package:hoyo_aio/features/checkin/presentation/widgets/check_in_calendar_card.dart';
import 'package:hoyo_aio/features/checkin/presentation/widgets/check_in_today_card.dart';
import 'package:hoyo_aio/features/dashboard/presentation/states/dashboard_error.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  final _claiming = <Game>{};

  Future<void> _claim(SavedRole role, CheckInMonth month) async {
    setState(() => _claiming.add(role.game));
    final l10n = context.l10n;
    final reward = month.todayReward;
    try {
      final outcome = await ref
          .read(checkInCalendarProvider(role.accountId, role.game).notifier)
          .claim();
      if (!mounted) return;
      switch (outcome) {
        case ClaimOutcome.claimed:
          showAppSnackbar(
            context,
            message: l10n.checkInClaimed(
              reward == null ? '' : l10n.rewardLabel(reward),
            ),
            icon: LucideIcons.check,
          );
        case ClaimOutcome.alreadyClaimed:
          showAppSnackbar(
            context,
            message: l10n.checkInAlreadyClaimed,
            icon: LucideIcons.check,
          );
        case ClaimOutcome.captcha:
          showAppSnackbar(
            context,
            message: l10n.checkInCaptcha,
            icon: LucideIcons.shieldAlert,
            actionLabel: l10n.dashboardOpenHoyolab,
            onAction: () => unawaited(openHoyolab()),
          );
      }
    } on AppException catch (error) {
      if (!mounted) return;
      showAppSnackbar(
        context,
        message: dashboardErrorMessage(error, l10n),
        icon: LucideIcons.wifiOff,
      );
    } finally {
      if (mounted) setState(() => _claiming.remove(role.game));
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(checkInRoleProvider);
    final games = ref.watch(checkInGamesProvider);
    final calendar = role == null
        ? null
        : ref.watch(checkInCalendarProvider(role.accountId, role.game));
    final month = calendar?.value;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            date: month?.date,
            games: games,
            selected: role?.game,
            onSelect: ref.read(checkInSelectedGameProvider.notifier).select,
          ),
          Expanded(
            child: role == null || calendar == null
                ? const _NoRoles()
                : _Body(
                    calendar: calendar,
                    isClaiming: _claiming.contains(role.game),
                    onClaim: (month) => unawaited(_claim(role, month)),
                    onRefresh: ref
                        .read(
                          checkInCalendarProvider(
                            role.accountId,
                            role.game,
                          ).notifier,
                        )
                        .refresh,
                  ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.calendar,
    required this.isClaiming,
    required this.onClaim,
    required this.onRefresh,
  });

  final AsyncValue<CheckInMonth> calendar;
  final bool isClaiming;
  final ValueChanged<CheckInMonth> onClaim;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => unawaited(onRefresh()),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.s8,
          AppSpacing.gutter,
          AppSpacing.s24,
        ),
        children: switch (calendar) {
          AsyncValue(value: final month?) => [
            CheckInTodayCard(
              month: month,
              isClaiming: isClaiming,
              onClaim: calendar.isLoading ? null : () => onClaim(month),
            ),
            const SizedBox(height: AppSpacing.cardGap),
            CheckInCalendarCard(month: month),
          ],
          AsyncError(:final error) => [
            DashboardError(error: error, onRetry: () => unawaited(onRefresh())),
          ],
          _ => const [_CheckInSkeleton()],
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.date,
    required this.games,
    required this.selected,
    required this.onSelect,
  });

  static const double _chipGap = 6;

  final DateTime? date;
  final List<Game> games;
  final Game? selected;
  final ValueChanged<Game> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final current = date;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.s16,
        AppSpacing.gutter,
        AppSpacing.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.s12,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.checkInTitle,
                  style: AppTextStyles.titleL.copyWith(color: colors.text),
                ),
              ),
              if (current != null) AppBadge(label: l10n.checkInDate(current)),
            ],
          ),
          if (games.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: _chipGap,
                children: [
                  for (final game in games)
                    GameSwitcherChip(
                      game: game,
                      label: l10n.gameShortName(game),
                      selected: game == selected,
                      onTap: () => onSelect(game),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NoRoles extends StatelessWidget {
  const _NoRoles();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.gutter),
    child: Text(
      context.l10n.checkInNoRoles,
      textAlign: TextAlign.center,
      style: AppTextStyles.bodyM.copyWith(color: context.colors.text2),
    ),
  );
}

class _CheckInSkeleton extends StatelessWidget {
  const _CheckInSkeleton();

  static const double _todayHeight = 92;
  static const double _calendarHeight = 420;

  @override
  Widget build(BuildContext context) {
    final block = context.colors.surface3;
    return Skeleton(
      child: Column(
        spacing: AppSpacing.cardGap,
        children: [
          for (final height in [_todayHeight, _calendarHeight])
            Container(
              height: height,
              decoration: BoxDecoration(
                color: block,
                borderRadius: BorderRadius.circular(AppRadius.tile),
              ),
            ),
        ],
      ),
    );
  }
}
