import 'package:material_ui/material_ui.dart';

abstract final class AppTextStyles {
  static const fontFamily = 'Inter';

  static const display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    height: 38 / 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 34 * -0.03,
  );
  static const headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 28 * -0.02,
  );
  static const titleL = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
  );
  static const titleM = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w700,
  );
  static const bodyL = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );
  static const bodyM = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w400,
  );
  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w600,
  );
  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
  );
  static const overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 11 * 0.08,
  );

  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w600,
  );
  static const buttonSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
  );
  static const chip = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 18 / 14,
    fontWeight: FontWeight.w600,
  );
  static const rowTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
  );
  static const rowSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
  );
  static const badge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
  );

  static TextStyle tabular(TextStyle style) =>
      style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static TextTheme textTheme(Color color) => TextTheme(
    displaySmall: display.copyWith(color: color),
    headlineMedium: headline.copyWith(color: color),
    titleLarge: titleL.copyWith(color: color),
    titleMedium: titleM.copyWith(color: color),
    bodyLarge: bodyL.copyWith(color: color),
    bodyMedium: bodyM.copyWith(color: color),
    labelLarge: label.copyWith(color: color),
    bodySmall: caption.copyWith(color: color),
    labelSmall: overline.copyWith(color: color),
  );
}
