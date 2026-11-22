import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class RosterChip extends StatelessWidget {
  const RosterChip({
    required this.label,
    required this.selected,
    this.dotColor,
    this.trailingIcon,
    this.onTap,
    super.key,
  });

  static const double _height = 36;
  static const double _hitHeight = 44;
  static const double _dot = 8;

  final String label;
  final bool selected;
  final Color? dotColor;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: _hitHeight,
          child: Center(
            child: Container(
              height: _height,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
              decoration: BoxDecoration(
                color: selected ? colors.surface2 : colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: selected ? colors.text : colors.border2,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.s8,
                children: [
                  if (dotColor != null)
                    Container(
                      width: _dot,
                      height: _dot,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    label,
                    style: AppTextStyles.chip.copyWith(color: colors.text),
                  ),
                  if (trailingIcon != null)
                    AppIcon(
                      trailingIcon!,
                      size: AppIconSize.badge,
                      color: colors.text2,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const rosterMenuIcon = LucideIcons.chevronDown;
const rosterSortIcon = LucideIcons.arrowUpDown;
