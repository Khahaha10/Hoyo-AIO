import 'package:hoyo_aio/core/design_system/components/pressable.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/app_colors.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:material_ui/material_ui.dart';

enum AppButtonVariant { primary, secondary, text, textDanger, danger }

enum AppButtonSize {
  regular(height: 52, horizontalPadding: 24, textStyle: AppTextStyles.button),
  medium(height: 48, horizontalPadding: 24, textStyle: AppTextStyles.button),
  small(
    height: 44,
    horizontalPadding: 18,
    textStyle: AppTextStyles.buttonSmall,
  );

  const AppButtonSize({
    required this.height,
    required this.horizontalPadding,
    required this.textStyle,
  });

  final double height;
  final double horizontalPadding;
  final TextStyle textStyle;
}

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final interactive = onPressed != null && !isLoading;
    final scheme = Theme.of(context).colorScheme;
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
            size: size,
            colors: context.colors,
            primary: scheme.primary,
            onPrimary: scheme.onPrimary,
            enabled: onPressed != null,
            pressed: pressed,
          ),
          label: label,
          icon: icon,
          trailingIcon: trailingIcon,
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
    required this.trailingIcon,
    required this.isLoading,
    required this.expand,
  });

  final _ButtonSpec spec;
  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
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
          if (trailingIcon != null && !isLoading)
            AppIcon(trailingIcon!, color: spec.foreground),
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
    required AppButtonSize size,
    required AppColors colors,
    required Color primary,
    required Color onPrimary,
    required bool enabled,
    required bool pressed,
  }) {
    _ButtonSpec sized({
      required Color? background,
      required Color foreground,
      Color? border,
    }) => _ButtonSpec(
      height: size.height,
      horizontalPadding: size.horizontalPadding,
      gap: 8,
      textStyle: size.textStyle,
      background: background,
      foreground: foreground,
      border: border,
    );

    return switch (variant) {
      AppButtonVariant.primary => sized(
        background: !enabled
            ? colors.surface3
            : pressed
            ? _pressedFill(primary)
            : primary,
        foreground: enabled ? onPrimary : colors.text3,
      ),
      AppButtonVariant.danger => sized(
        background: !enabled
            ? colors.surface3
            : pressed
            ? _pressedFill(colors.danger)
            : colors.danger,
        foreground: enabled ? colors.bg : colors.text3,
      ),
      AppButtonVariant.secondary => sized(
        background: pressed ? colors.surface2 : colors.surface,
        foreground: enabled ? colors.text : colors.text3,
        border: enabled ? colors.border2 : colors.border,
      ),
      AppButtonVariant.text || AppButtonVariant.textDanger => _ButtonSpec(
        height: AppButtonSize.small.height,
        horizontalPadding: 16,
        gap: 6,
        textStyle: AppTextStyles.buttonSmall,
        background: pressed ? colors.surface2 : null,
        foreground: !enabled
            ? colors.text3
            : variant == AppButtonVariant.textDanger
            ? colors.danger
            : colors.text,
        border: null,
      ),
    };
  }

  static Color _pressedFill(Color fill) => fill == BrandColors.lime
      ? BrandColors.limePressed
      : Color.alphaBlend(const Color.fromRGBO(0, 0, 0, .08), fill);

  final double height;
  final double horizontalPadding;
  final double gap;
  final TextStyle textStyle;
  final Color? background;
  final Color foreground;
  final Color? border;
}
