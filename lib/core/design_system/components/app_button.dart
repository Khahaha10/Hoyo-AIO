import 'package:hoyo_aio/core/design_system/components/pressable.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/app_colors.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:material_ui/material_ui.dart';

enum AppButtonVariant { primary, secondary, text }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final interactive = onPressed != null && !isLoading;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      onTap: interactive ? onPressed : null,
      excludeSemantics: true,
      child: Pressable(
        onTap: interactive ? onPressed : null,
        builder: (context, pressed) => _ButtonBody(
          spec: _ButtonSpec.resolve(
            variant: variant,
            colors: context.colors,
            primary: Theme.of(context).colorScheme.primary,
            onPrimary: Theme.of(context).colorScheme.onPrimary,
            enabled: onPressed != null,
            pressed: pressed,
          ),
          label: label,
          icon: icon,
          isLoading: isLoading,
          expand: expand,
        ),
      ),
    );
  }
}

class _ButtonBody extends StatelessWidget {
  const _ButtonBody({
    required this.spec,
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.expand,
  });

  final _ButtonSpec spec;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final leading = isLoading
        ? SizedBox.square(
            dimension: AppIconSize.regular.pixels,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: spec.foreground,
            ),
          )
        : icon == null
        ? null
        : AppIcon(icon!, color: spec.foreground);
    return Container(
      height: spec.height,
      padding: EdgeInsets.symmetric(horizontal: spec.horizontalPadding),
      decoration: BoxDecoration(
        color: spec.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: spec.border == null ? null : Border.all(color: spec.border!),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: spec.gap,
        children: [
          ?leading,
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: spec.textStyle.copyWith(color: spec.foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonSpec {
  const _ButtonSpec({
    required this.height,
    required this.horizontalPadding,
    required this.gap,
    required this.textStyle,
    required this.background,
    required this.foreground,
    required this.border,
  });

  factory _ButtonSpec.resolve({
    required AppButtonVariant variant,
    required AppColors colors,
    required Color primary,
    required Color onPrimary,
    required bool enabled,
    required bool pressed,
  }) {
    return switch (variant) {
      AppButtonVariant.primary => _ButtonSpec(
        height: 52,
        horizontalPadding: 24,
        gap: 8,
        textStyle: AppTextStyles.button,
        background: !enabled
            ? colors.surface3
            : pressed
            ? _pressedFill(primary)
            : primary,
        foreground: enabled ? onPrimary : colors.text3,
        border: null,
      ),
      AppButtonVariant.secondary => _ButtonSpec(
        height: 52,
        horizontalPadding: 24,
        gap: 8,
        textStyle: AppTextStyles.button,
        background: pressed ? colors.surface2 : colors.surface,
        foreground: enabled ? colors.text : colors.text3,
        border: enabled ? colors.border2 : colors.border,
      ),
      AppButtonVariant.text => _ButtonSpec(
        height: 44,
        horizontalPadding: 16,
        gap: 6,
        textStyle: AppTextStyles.buttonSmall,
        background: pressed ? colors.surface2 : null,
        foreground: enabled ? colors.text : colors.text3,
        border: null,
      ),
    };
  }

  static Color _pressedFill(Color primary) => primary == BrandColors.lime
      ? BrandColors.limePressed
      : Color.alphaBlend(const Color.fromRGBO(0, 0, 0, .08), primary);

  final double height;
  final double horizontalPadding;
  final double gap;
  final TextStyle textStyle;
  final Color? background;
  final Color foreground;
  final Color? border;
}
