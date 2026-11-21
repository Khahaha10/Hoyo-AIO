import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_snackbar.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/error/app_exception_l10n.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/game_labels.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/domain/detected_role.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/pending_account_provider.dart';
import 'package:hoyo_aio/features/accounts/presentation/widgets/account_flow_header.dart';
import 'package:hoyo_aio/features/accounts/presentation/widgets/game_roles_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class SelectRolesScreen extends ConsumerStatefulWidget {
  const SelectRolesScreen({super.key});

  @override
  ConsumerState<SelectRolesScreen> createState() => _SelectRolesScreenState();
}

class _SelectRolesScreenState extends ConsumerState<SelectRolesScreen> {
  late final PendingAccount? _pending;
  late final PendingAccountController _controller;
  late Set<DetectedRole> _selected;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _pending = ref.read(pendingAccountControllerProvider);
    _controller = ref.read(pendingAccountControllerProvider.notifier);
    _selected = {...?_pending?.roles};
  }

  List<DetectedRole> get _roles => _pending?.roles ?? const [];

  bool get _allSelected => _selected.length == _roles.length;

  void _toggle(DetectedRole role) => setState(() {
    _selected = _selected.contains(role)
        ? ({..._selected}..remove(role))
        : {..._selected, role};
  });

  void _toggleAll() =>
      setState(() => _selected = _allSelected ? {} : {..._roles});

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      await _controller.confirm(_selected);
      if (mounted) context.go(AppRoutes.dashboard);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackbar(
        context,
        message: e.localizedMessage(context.l10n),
        icon: LucideIcons.circleAlert,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_saving) _controller.clear();
      },
      child: Scaffold(
        body: SafeArea(
          child: pending == null
              ? const _SessionExpired()
              : _buildRoles(context, pending),
        ),
      ),
    );
  }

  Widget _buildRoles(BuildContext context, PendingAccount pending) {
    final l10n = context.l10n;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.s24),
            children: [
              AccountFlowHeader(
                title: l10n.selectRolesTitle,
                subtitle: l10n.selectRolesSubtitle(
                  _roles.length,
                  groupUid(pending.hoyolabUid),
                ),
                trailing: AppButton(
                  label: _allSelected
                      ? l10n.selectRolesClearAll
                      : l10n.selectRolesSelectAll,
                  variant: AppButtonVariant.text,
                  expand: false,
                  onPressed: _saving ? null : _toggleAll,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.s16,
                  AppSpacing.gutter,
                  0,
                ),
                child: Column(
                  spacing: AppSpacing.s12,
                  children: [
                    for (final game in Game.values)
                      if (_roles.where((r) => r.game == game).toList()
                          case final roles when roles.isNotEmpty)
                        GameRolesCard(
                          game: game,
                          roles: roles,
                          selected: _selected,
                          onToggle: _saving ? (_) {} : _toggle,
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.s12,
            AppSpacing.gutter,
            AppSpacing.s24,
          ),
          child: AppButton(
            label: l10n.selectRolesAdd(_selected.length),
            isLoading: _saving,
            onPressed: _selected.isEmpty || _saving ? null : _confirm,
          ),
        ),
      ],
    );
  }
}

class _SessionExpired extends StatelessWidget {
  const _SessionExpired();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Expanded(
          child: AccountFlowHeader(
            title: l10n.selectRolesTitle,
            subtitle: l10n.selectRolesSessionExpired,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.s12,
            AppSpacing.gutter,
            AppSpacing.s24,
          ),
          child: AppButton(
            label: l10n.addAccountTitle,
            onPressed: () => context.go(AppRoutes.addAccount),
          ),
        ),
      ],
    );
  }
}
