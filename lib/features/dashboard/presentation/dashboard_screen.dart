import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
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
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';
import 'package:hoyo_aio/features/dashboard/domain/note_result.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/dashboard/presentation/game_layouts/genshin_layout.dart';
import 'package:hoyo_aio/features/dashboard/presentation/game_layouts/star_rail_layout.dart';
import 'package:hoyo_aio/features/dashboard/presentation/game_layouts/zzz_layout.dart';
import 'package:hoyo_aio/features/dashboard/presentation/providers/notes_provider.dart';
import 'package:hoyo_aio/features/dashboard/presentation/states/cookie_expired_banner.dart';
import 'package:hoyo_aio/features/dashboard/presentation/states/dashboard_empty.dart';
import 'package:hoyo_aio/features/dashboard/presentation/states/dashboard_error.dart';
import 'package:hoyo_aio/features/dashboard/presentation/states/dashboard_skeleton.dart';
import 'package:hoyo_aio/features/dashboard/presentation/states/refreshing_indicator.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/role_switcher_sheet.dart';
import 'package:hoyo_aio/features/notifications/presentation/providers/notification_log_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({this.deepLinkGame, this.deepLinkRoleUid, super.key});

  final String? deepLinkGame;
  final String? deepLinkRoleUid;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  ({String? game, String? uid})? _pendingDeepLink;
  final _bannerDismissedFor = <String>{};

  @override
  void initState() {
    super.initState();
    _rememberDeepLink();
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deepLinkGame != widget.deepLinkGame ||
        oldWidget.deepLinkRoleUid != widget.deepLinkRoleUid) {
      _rememberDeepLink();
    }
  }

  void _rememberDeepLink() {
    if (widget.deepLinkGame == null && widget.deepLinkRoleUid == null) return;
    _pendingDeepLink = (game: widget.deepLinkGame, uid: widget.deepLinkRoleUid);
  }

  void _applyDeepLink(List<SavedRole> roles) {
    final link = _pendingDeepLink;
    if (link == null || roles.isEmpty) return;
    _pendingDeepLink = null;
    final match = roles
        .where(
          (role) =>
              (link.game == null || role.game.name == link.game) &&
              (link.uid == null || role.uid == link.uid),
        )
        .firstOrNull;
    if (match == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(selectedRoleIdProvider.notifier).select(match.id);
    });
  }

  void _showRefreshError(
    AsyncValue<NoteResult>? previous,
    AsyncValue<NoteResult> next,
    Future<void> Function() retry,
  ) {
    final finishedRefresh = (previous?.isLoading ?? false) && !next.isLoading;
    final error = next.value?.error ?? next.error;
    if (!finishedRefresh || error == null || !next.hasValue) return;
    if (error is CookieExpiredException) return;
    final l10n = context.l10n;
    showAppSnackbar(
      context,
      message: dashboardErrorMessage(error, l10n),
      icon: LucideIcons.wifiOff,
      actionLabel: l10n.commonRetry,
      onAction: () => unawaited(retry()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(dashboardRolesProvider);
    _applyDeepLink(roles);
    final role = ref.watch(selectedRoleProvider);
    if (role == null) return const DashboardEmpty();
    final notes = ref.watch(notesProvider(role));
    final notifier = ref.read(notesProvider(role).notifier);
    ref
      ..listen(
        notesProvider(role),
        (previous, next) => _showRefreshError(previous, next, notifier.refresh),
      )
      ..watch(clockTickProvider);
    final now = ref.watch(clockProvider)();
    final account = ref
        .watch(accountsProvider)
        .value
        ?.where((a) => a.id == role.accountId)
        .firstOrNull;
    final result = notes.value;
    final cookieRejected =
        (account?.needsAttention ?? false) ||
        result?.error is CookieExpiredException;
    final isRefreshing = notes.isLoading && notes.hasValue;
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
          onRefresh: notes.isLoading ? null : notifier.refresh,
          onOpenDatabook: () => context.go(AppRoutes.databook),
          onOpenInbox: () => context.push(AppRoutes.inbox),
          unreadCount: ref.watch(unreadNotificationCountProvider),
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
                if (isRefreshing)
                  RefreshingIndicator(game: role.game)
                else ...[
                  _LastUpdatedRow(fetchedAt: result?.note.fetchedAt, now: now),
                  const SizedBox(height: AppSpacing.s12),
                ],
                if (cookieRejected &&
                    result != null &&
                    !_bannerDismissedFor.contains(role.accountId)) ...[
                  CookieExpiredBanner(
                    name: account?.nickname ?? role.nickname,
                    dataFrom: result.note.fetchedAt,
                    onLater: () =>
                        setState(() => _bannerDismissedFor.add(role.accountId)),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                ],
                switch (notes) {
                  AsyncValue(value: final value?) => _NoteContent(
                    note: value.note,
                    now: now,
                    isStale: value.isStale || cookieRejected,
                  ),
                  AsyncError(:final error) => DashboardError(
                    error: error,
                    onRetry: notifier.refresh,
                  ),
                  _ => const DashboardSkeleton(),
                },
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NoteContent extends StatelessWidget {
  const _NoteContent({
    required this.note,
    required this.now,
    required this.isStale,
  });

  final GameNote note;
  final DateTime now;
  final bool isStale;

  @override
  Widget build(BuildContext context) => switch (note) {
    final GenshinNote note => GenshinLayout(
      note: note,
      now: now,
      isStale: isStale,
    ),
    final StarRailNote note => StarRailLayout(
      note: note,
      now: now,
      isStale: isStale,
    ),
    final ZzzNote note => ZzzLayout(note: note, now: now, isStale: isStale),
  };
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
