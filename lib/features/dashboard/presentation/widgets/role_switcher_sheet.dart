import 'package:hoyo_aio/core/design_system/components/settings_row.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/game_labels.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

Future<void> showRoleSwitcherSheet(
  BuildContext context, {
  required List<SavedRole> roles,
  required SavedRole current,
  required ValueChanged<SavedRole> onSelect,
}) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: context.colors.surface,
  barrierColor: context.colors.scrim,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.dialog)),
  ),
  builder: (sheetContext) => _RoleSwitcherSheet(
    roles: roles,
    current: current,
    onSelect: (role) {
      Navigator.of(sheetContext).pop();
      onSelect(role);
    },
  ),
);

class _RoleSwitcherSheet extends StatelessWidget {
  const _RoleSwitcherSheet({
    required this.roles,
    required this.current,
    required this.onSelect,
  });

  final List<SavedRole> roles;
  final SavedRole current;
  final ValueChanged<SavedRole> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.s16,
          children: [
            Text(
              l10n.dashboardSwitchRole,
              style: AppTextStyles.screenTitle.copyWith(color: colors.text),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: SettingsCard(
                  children: [
                    for (final role in roles)
                      SettingsRow(
                        icon: LucideIcons.gamepad2,
                        title:
                            '${role.nickname} · ${l10n.gameShortName(role.game)}',
                        subtitle:
                            '${l10n.gameLevel(role.game, role.level)} · '
                            '${groupUid(role.uid)}',
                        trailing: role.id == current.id
                            ? AppIcon(LucideIcons.check, color: colors.text)
                            : null,
                        onTap: () => onSelect(role),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
