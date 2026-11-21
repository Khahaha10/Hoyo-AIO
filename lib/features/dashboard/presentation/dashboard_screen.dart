import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/error/app_exception_l10n.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/selected_role_provider.dart';
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';
import 'package:hoyo_aio/features/dashboard/domain/note_result.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/dashboard/presentation/game_layouts/genshin_layout.dart';
import 'package:hoyo_aio/features/dashboard/presentation/game_layouts/star_rail_layout.dart';
import 'package:hoyo_aio/features/dashboard/presentation/game_layouts/zzz_layout.dart';
import 'package:hoyo_aio/features/dashboard/presentation/providers/notes_provider.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/role_switcher_sheet.dart';
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

  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(dashboardRolesProvider);
    _applyDeepLink(roles);
    final role = ref.watch(selectedRoleProvider);
    if (role == null) return const _NoRoles();
    final notes = ref.watch(notesProvider(role));
    final notifier = ref.read(notesProvider(role).notifier);
    ref.watch(clockTickProvider);
    final now = ref.watch(clockProvider)();
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
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                AppSpacing.s24,
              ),
              children: [
                _LastUpdatedRow(
                  fetchedAt: notes.value?.note.fetchedAt,
                  now: now,
                ),
                const SizedBox(height: AppSpacing.s12),
                switch (notes) {
                  AsyncValue(value: final result?) => _NoteContent(
                    result: result,
                    now: now,
                  ),
                  AsyncError(:final error) => _ErrorContent(
                    error: error,
                    onRetry: notifier.refresh,
                  ),
                  _ => const _LoadingContent(),
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
  const _NoteContent({required this.result, required this.now});

  final NoteResult result;
  final DateTime now;

  @override
  Widget build(BuildContext context) => switch (result.note) {
    final GenshinNote note => GenshinLayout(
      note: note,
      now: now,
      isStale: result.isStale,
    ),
    final StarRailNote note => StarRailLayout(
      note: note,
      now: now,
      isStale: result.isStale,
    ),
    final ZzzNote note => ZzzLayout(
      note: note,
      now: now,
      isStale: result.isStale,
    ),
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

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: AppSpacing.s40),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = error is AppException
        ? (error as AppException).localizedMessage(l10n)
        : l10n.errorUnknown;
    return Column(
      spacing: AppSpacing.s12,
      children: [
        const SizedBox(height: AppSpacing.s24),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyM.copyWith(color: context.colors.text2),
        ),
        AppButton(
          label: l10n.commonRetry,
          variant: AppButtonVariant.secondary,
          expand: false,
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class _NoRoles extends StatelessWidget {
  const _NoRoles();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s8,
        children: [
          Text(
            context.l10n.navDashboard,
            style: AppTextStyles.headline.copyWith(color: context.colors.text),
          ),
          Text(
            context.l10n.dashboardNoRoles,
            style: AppTextStyles.bodyM.copyWith(color: context.colors.text2),
          ),
        ],
      ),
    ),
  );
}
