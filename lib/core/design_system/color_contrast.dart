import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:material_ui/material_ui.dart';

double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

Color onColorFor(Color background) =>
    contrastRatio(BrandColors.ink, background) >=
        contrastRatio(BrandColors.white, background)
    ? BrandColors.ink
    : BrandColors.white;
