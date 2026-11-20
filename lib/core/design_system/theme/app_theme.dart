import 'package:hoyo_aio/core/design_system/color_contrast.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/app_colors.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/app_elevation.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/game_colors.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:material_ui/material_ui.dart';

abstract final class AppTheme {
  static ThemeData light({Color? accent, ColorScheme? dynamicScheme}) => _build(
    brightness: Brightness.light,
    colors: AppColors.light,
    games: GameColors.light,
    elevation: AppElevation.light,
    accent: accent,
    dynamicScheme: dynamicScheme,
  );

  static ThemeData dark({Color? accent, ColorScheme? dynamicScheme}) => _build(
    brightness: Brightness.dark,
    colors: AppColors.dark,
    games: GameColors.dark,
    elevation: AppElevation.dark,
    accent: accent,
    dynamicScheme: dynamicScheme,
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppColors colors,
    required GameColors games,
    required AppElevation elevation,
    required Color? accent,
    required ColorScheme? dynamicScheme,
  }) {
    final primary = dynamicScheme?.primary ?? accent ?? BrandColors.lime;
    final onPrimary = dynamicScheme?.onPrimary ?? onColorFor(primary);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: dynamicScheme?.primaryContainer ?? primary,
      onPrimaryContainer: dynamicScheme?.onPrimaryContainer ?? onPrimary,
      secondary: primary,
      onSecondary: onPrimary,
      error: colors.danger,
      onError: colors.bg,
      errorContainer: colors.dangerBg,
      onErrorContainer: colors.danger,
      surface: colors.surface,
      onSurface: colors.text,
      onSurfaceVariant: colors.text2,
      surfaceContainerLowest: colors.surface,
      surfaceContainerLow: colors.surface2,
      surfaceContainer: colors.surface2,
      surfaceContainerHigh: colors.surface3,
      surfaceContainerHighest: colors.surface3,
      outline: colors.border2,
      outlineVariant: colors.border,
      inverseSurface: colors.inverse,
      onInverseSurface: colors.onInverse,
      scrim: colors.scrim,
      shadow: const Color(0xFF101828),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.bg,
      canvasColor: colors.bg,
      dividerColor: colors.border,
      fontFamily: AppTextStyles.fontFamily,
      textTheme: AppTextStyles.textTheme(colors.text),
      extensions: [colors, games, elevation],
    );
  }
}
