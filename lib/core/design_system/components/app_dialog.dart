import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String body,
  required String cancelLabel,
  required String confirmLabel,
  bool isDestructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: context.colors.scrim,
    builder: (_) => AppConfirmDialog(
      icon: icon,
      title: title,
      body: body,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      isDestructive: isDestructive,
    ),
  );
  return result ?? false;
}

class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    required this.icon,
    required this.title,
    required this.body,
    required this.cancelLabel,
    required this.confirmLabel,
    this.isDestructive = true,
    super.key,
  });

  static const double _iconTile = 48;
  static const double _iconTileRadius = 16;

  final IconData icon;
  final String title;
  final String body;
  final String cancelLabel;
  final String confirmLabel;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSpacing.s24),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.dialog),
          border: Border.all(color: colors.border),
          boxShadow: context.elevation.dialog,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.s16,
          children: [
            Container(
              width: _iconTile,
              height: _iconTile,
              decoration: BoxDecoration(
                color: isDestructive ? colors.dangerBg : colors.surface2,
                borderRadius: BorderRadius.circular(_iconTileRadius),
              ),
              child: AppIcon(
                icon,
                color: isDestructive ? colors.danger : colors.text,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.s8,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleL.copyWith(
                    fontSize: 20,
                    height: 26 / 20,
                    color: colors.text,
                  ),
                ),
                Text(
                  body,
                  style: AppTextStyles.bodyM.copyWith(color: colors.text2),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s4),
              child: Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: AppButton(
                      label: cancelLabel,
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.medium,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  Expanded(
                    child: AppButton(
                      label: confirmLabel,
                      variant: isDestructive
                          ? AppButtonVariant.danger
                          : AppButtonVariant.primary,
                      size: AppButtonSize.medium,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
