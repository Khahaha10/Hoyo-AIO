import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:material_ui/material_ui.dart';

class RadioOptionCard extends StatelessWidget {
  const RadioOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.highlightIcon = false,
    this.badge,
    super.key,
  });

  static const cardKey = ValueKey('radio-option-card');
  static const double _iconTile = 44;
  static const double _iconTileRadius = 14;
  static const double _radio = 24;
  static const double _radioSelectedBorder = 7;

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final bool highlightIcon;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: onTap != null,
      label: '$title. $subtitle',
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          key: cardKey,
          padding: const EdgeInsets.all(AppSpacing.s20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.hero),
            border: Border.all(
              color: selected ? colors.text : colors.border,
              width: 2,
            ),
            boxShadow: context.elevation.card,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.s16,
            children: [
              Container(
                width: _iconTile,
                height: _iconTile,
                decoration: BoxDecoration(
                  color: highlightIcon ? BrandColors.lime : colors.surface2,
                  borderRadius: BorderRadius.circular(_iconTileRadius),
                ),
                child: AppIcon(
                  icon,
                  color: highlightIcon ? BrandColors.ink : colors.text,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.rowTitle.copyWith(
                            color: colors.text,
                          ),
                        ),
                        ?badge,
                      ],
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.rowSubtitle.copyWith(
                        color: colors.text2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: _radio,
                height: _radio,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? colors.text : colors.border2,
                    width: selected ? _radioSelectedBorder : 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
