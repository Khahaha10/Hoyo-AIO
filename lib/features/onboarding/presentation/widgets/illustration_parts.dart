import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

class FloatingChip extends StatelessWidget {
  const FloatingChip({
    required this.label,
    this.dotColor,
    this.icon,
    this.iconColor,
    super.key,
  });

  static const double _height = 36;
  static const double _dot = 8;

  final String label;
  final Color? dotColor;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.border),
        boxShadow: context.elevation.card,
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
          if (icon != null)
            AppIcon(icon!, size: AppIconSize.inline, color: iconColor),
          Text(
            label,
            style: AppTextStyles.tabular(AppTextStyles.label)
                .copyWith(color: colors.text),
          ),
        ],
      ),
    );
  }
}

class MiniCard extends StatelessWidget {
  const MiniCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.s16),
    this.radius = AppRadius.hero,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colors.border),
        boxShadow: context.elevation.card,
      ),
      child: child,
    );
  }
}

class MiniBar extends StatelessWidget {
  const MiniBar({required this.fraction, required this.color, super.key});

  static const double _height = 6;

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: context.colors.surface3,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: FractionallySizedBox(
        widthFactor: fraction,
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
    );
  }
}

class PlaceholderTile extends StatelessWidget {
  const PlaceholderTile({this.size = 40, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: context.colors.surface3,
      borderRadius: BorderRadius.circular(AppRadius.iconTile),
    ),
  );
}
