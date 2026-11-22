import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/core/design_system/components/app_snackbar.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/selected_role_provider.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/dashboard/presentation/states/cookie_expired_banner.dart';
import 'package:hoyo_aio/features/dashboard/presentation/states/dashboard_empty.dart';
import 'package:hoyo_aio/features/dashboard/presentation/states/dashboard_error.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/role_switcher_sheet.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_repository.dart';
import 'package:hoyo_aio/features/databook/presentation/providers/databook_provider.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/characters_card.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/databook_skeleton.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/endgame_card.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/private_card.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/stale_row.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/summary_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class DatabookScreen extends ConsumerStatefulWidget {
  const DatabookScreen({super.key});

  @override
  ConsumerState<DatabookScreen> createState() => _DatabookScreenState();
}

class _DatabookScreenState extends ConsumerState<DatabookScreen> {
  static const double _staleOpacity = 0.55;

  final _bannerDismissedFor = <String>{};
  final _privateDismissedFor = <int>{};
  var _makingPublic = false;

  Future<void> _makePublic(SavedRole role) async {
    final l10n = context.l10n;
    setState(() => _makingPublic = true);
    try {
      await ref.read(databookProvider(role).notifier).makePublic();
      if (mounted) {
        showAppSnackbar(
          context,
          message: l10n.databookMadePublic,
          icon: LucideIcons.check,
        );
      }
    } on AppException {
      if (mounted) {
        showAppSnackbar(
          context,
          message: l10n.databookMakePublicFailed,
          icon: LucideIcons.wifiOff,
        );
      }
    } finally {
      if (mounted) setState(() => _makingPublic = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(dashboardRolesProvider);
    final role = ref.watch(selectedRoleProvider);
    if (role == null) return const DashboardEmpty();
    final databook = ref.watch(databookProvider(role));
    final notifier = ref.read(databookProvider(role).notifier);
    ref.watch(clockTickProvider);
    final now = ref.watch(clockProvider)();
    final account = ref
        .watch(accountsProvider)
        .value
        ?.where((a) => a.id == role.accountId)
        .firstOrNull;
    final data = databook.value;
    final cookieRejected = account?.needsAttention ?? false;
    final stale = (data?.isStale ?? false) || cookieRejected;
    return Column(
      children: [
        DashboardHeader(
          role: role,
          games: [
            for (final game in dashboardGames)
              if (roles.any((r) => r.game == game)) game,
          ],
          onSelectGame: ref.read(selectedRoleIdProvider.notifier).selectGame,
          onSwitchRole: roles.length > 1
              ? () => showRoleSwitcherSheet(
                  context,
                  roles: roles,
                  current: role,
                  onSelect: (picked) => ref
                      .read(selectedRoleIdProvider.notifier)
                      .select(picked.id),
                )
              : null,
          onRefresh: databook.isLoading ? null : notifier.refresh,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => unawaited(notifier.refresh()),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                AppSpacing.s24,
              ),
              children: [
                if (data != null) ...[
                  _LastUpdatedRow(fetchedAt: data.fetchedAt, now: now),
                  const SizedBox(height: AppSpacing.s12),
                  if (cookieRejected &&
                      !_bannerDismissedFor.contains(role.accountId)) ...[
                    CookieExpiredBanner(
                      name: account?.nickname ?? role.nickname,
                      dataFrom: data.fetchedAt ?? now,
                      onLater: () => setState(
                        () => _bannerDismissedFor.add(role.accountId),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                  ] else if (!cookieRejected && data.isStale) ...[
                    StaleRow(
                      fetchedAt: data.fetchedAt,
                      onRetry: notifier.refresh,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                  ],
                ],
                switch (databook) {
                  AsyncValue(value: final data?) => Opacity(
                    opacity: stale ? _staleOpacity : 1,
                    child: _Content(data: data, role: role, now: now),
                  ),
                  AsyncError(:final error) when isChroniclePrivate(error) =>
                    _privateDismissedFor.contains(role.id)
                        ? const _NothingToShow()
                        : PrivateCard(
                            busy: _makingPublic,
                            onMakePublic: () => unawaited(_makePublic(role)),
                            onNotNow: () => setState(
                              () => _privateDismissedFor.add(role.id),
                            ),
                          ),
                  AsyncError(:final error) => DashboardError(
                    error: error,
                    onRetry: notifier.refresh,
                  ),
                  _ => const DatabookSkeleton(),
                },
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data, required this.role, required this.now});

  final DatabookData data;
  final SavedRole role;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = data.summary?.data;
    final characters = data.characters?.data ?? const [];
    final endgame = data.endgame?.data ?? const [];
    if (summary == null && characters.isEmpty && endgame.isEmpty) {
      return const _NothingToShow();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.s12,
      children: [
        if (summary != null) SummaryCard(summary: summary),
        if (characters.isNotEmpty)
          CharactersCard(game: role.game, characters: characters),
        if (endgame.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.s4,
              top: AppSpacing.s4,
            ),
            child: Text(
              l10n.databookEndgameSection.toUpperCase(),
              style: AppTextStyles.overline.copyWith(
                color: context.colors.text2,
              ),
            ),
          ),
          for (final summary in endgame)
            EndgameCard(summary: summary, now: now),
        ],
      ],
    );
  }
}

class _NothingToShow extends StatelessWidget {
  const _NothingToShow();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s40),
    child: Text(
      context.l10n.databookNoData,
      textAlign: TextAlign.center,
      style: AppTextStyles.bodyM.copyWith(color: context.colors.text2),
    ),
  );
}

class _LastUpdatedRow extends StatelessWidget {
  const _LastUpdatedRow({required this.fetchedAt, required this.now});

  final DateTime? fetchedAt;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final style = AppTextStyles.caption.copyWith(color: colors.text3);
    final at = fetchedAt;
    return Row(
      children: [
        if (at != null) ...[
          AppIcon(
            LucideIcons.clock,
            size: AppIconSize.badge,
            color: colors.text3,
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(child: Text(l10n.lastUpdated(at, now), style: style)),
        ] else
          const Spacer(),
        Text(l10n.dashboardPullToRefresh, style: style),
      ],
    );
  }
}
