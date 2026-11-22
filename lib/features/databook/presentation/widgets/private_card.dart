import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class PrivateCard extends StatelessWidget {
  const PrivateCard({
    required this.busy,
    required this.onMakePublic,
    required this.onNotNow,
    super.key,
  });

  static const double _iconTile = 40;
  static const double _ghostHeight = 56;

  final bool busy;
  final VoidCallback onMakePublic;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.s16,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.s12,
            children: [
              Container(
                width: _iconTile,
                height: _iconTile,
                decoration: BoxDecoration(
                  color: colors.surface2,
                  borderRadius: BorderRadius.circular(AppRadius.iconTile),
                ),
                child: AppIcon(LucideIcons.lock, color: colors.text),
              ),
              Semantics(
                header: true,
                child: Text(
                  l10n.databookPrivateTitle,
                  style: AppTextStyles.titleL.copyWith(color: colors.text),
                ),
              ),
              Text(
                l10n.databookPrivateBody,
                style: AppTextStyles.bodyM.copyWith(color: colors.text2),
              ),
              Row(
                spacing: AppSpacing.s8,
                children: [
                  AppButton(
                    label: l10n.databookMakePublic,
                    icon: LucideIcons.eye,
                    size: AppButtonSize.small,
                    expand: false,
                    isLoading: busy,
                    onPressed: onMakePublic,
                  ),
                  AppButton(
                    label: l10n.databookNotNow,
                    variant: AppButtonVariant.text,
                    size: AppButtonSize.small,
                    expand: false,
                    onPressed: busy ? null : onNotNow,
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.s12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.tile),
            border: Border.all(color: colors.border2),
          ),
          child: Column(
            spacing: AppSpacing.s8,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  height: _ghostHeight,
                  decoration: BoxDecoration(
                    color: colors.surface2,
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                ),
            ],
          ),
        ),
        Text(
          l10n.databookPrivateFootnote,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(color: colors.text3),
        ),
      ],
    );
  }
}
