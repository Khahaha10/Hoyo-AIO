import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/design_system/color_contrast.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/app_colors.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/game_colors.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('contrastRatio', () {
    test('black on white is 21:1 and is symmetric', () {
      const black = Color(0xFF000000);
      const white = Color(0xFFFFFFFF);
      expect(contrastRatio(black, white), closeTo(21, 0.01));
      expect(contrastRatio(white, black), closeTo(21, 0.01));
    });

    test('same color is 1:1', () {
      expect(contrastRatio(BrandColors.lime, BrandColors.lime), 1);
    });
  });

  group('onColorFor', () {
    test('lime gets ink, never white', () {
      expect(onColorFor(BrandColors.lime), BrandColors.ink);
    });

    test('a dark accent gets white', () {
      expect(onColorFor(const Color(0xFF1F62B0)), const Color(0xFFFFFFFF));
    });
  });

  group('design contrast (WCAG AA 4.5:1)', () {
    for (final (name, colors) in [
      ('light', AppColors.light),
      ('dark', AppColors.dark),
    ]) {
      for (final (label, fg) in [
        ('text', colors.text),
        ('text-2', colors.text2),
        ('text-3', colors.text3),
      ]) {
        test('$name $label on bg and surface', () {
          expect(contrastRatio(fg, colors.bg), greaterThanOrEqualTo(4.5));
          expect(contrastRatio(fg, colors.surface), greaterThanOrEqualTo(4.5));
        });
      }
    }

    test('ink on lime is at least 12:1', () {
      expect(
        contrastRatio(BrandColors.ink, BrandColors.lime),
        greaterThanOrEqualTo(12),
      );
    });

    test('accent ink is readable on surface in both themes', () {
      for (final game in Game.values) {
        expect(
          contrastRatio(
            GameColors.light.of(game).accInk,
            AppColors.light.surface,
          ),
          greaterThanOrEqualTo(4.5),
          reason: '$game light',
        );
        expect(
          contrastRatio(
            GameColors.dark.of(game).accInk,
            AppColors.dark.surface,
          ),
          greaterThanOrEqualTo(4.5),
          reason: '$game dark',
        );
      }
    });
  });
}
