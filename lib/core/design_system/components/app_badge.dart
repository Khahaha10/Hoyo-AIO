import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/app_colors.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

enum AppBadgeVariant { neutral, success, danger, warning }

class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    this.variant = AppBadgeVariant.neutral,
    this.icon,
    super.key,
  });

  static const double _height = 24;
  static const double _horizontalPadding = 10;
  static const double _gap = 4;

  final String label;
  final AppBadgeVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = _palette(context.colors);
    return Container(
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: _gap,
        children: [
          if (icon != null)
            AppIcon(icon!, size: AppIconSize.badge, color: foreground),
          Text(label, style: AppTextStyles.badge.copyWith(color: foreground)),
        ],
      ),
    );
  }

  (Color, Color, Color?) _palette(AppColors c) => switch (variant) {
    AppBadgeVariant.neutral => (c.surface2, c.text, c.border),
    AppBadgeVariant.success => (c.successBg, c.success, null),
    AppBadgeVariant.danger => (c.dangerBg, c.danger, null),
    AppBadgeVariant.warning => (c.warningBg, c.warning, null),
  };
}
