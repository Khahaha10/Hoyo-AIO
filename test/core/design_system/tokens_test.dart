import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/app_colors.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/game_colors.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_motion.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('BrandColors', () {
    test('lime, ink and pressed lime match the design', () {
      expect(BrandColors.lime, const Color(0xFFD2E843));
      expect(BrandColors.ink, const Color(0xFF1B1D16));
      expect(BrandColors.limePressed, const Color(0xFFBFD338));
    });
  });

  group('AppColors.light', () {
    const c = AppColors.light;

    test('neutrals match the design', () {
      expect(c.bg, const Color(0xFFF6F7F9));
      expect(c.surface, const Color(0xFFFFFFFF));
      expect(c.surface2, const Color(0xFFF1F3F6));
      expect(c.surface3, const Color(0xFFE6E9EE));
      expect(c.text, const Color(0xFF14161B));
      expect(c.text2, const Color(0xFF4A5060));
      expect(c.text3, const Color(0xFF5F6676));
      expect(c.border, const Color.fromRGBO(15, 17, 21, .08));
      expect(c.border2, const Color.fromRGBO(15, 17, 21, .16));
      expect(c.inverse, const Color(0xFF14161B));
      expect(c.onInverse, const Color(0xFFF2F3F5));
      expect(c.scrim, const Color.fromRGBO(15, 17, 21, .45));
    });

    test('status colors match the design', () {
      expect(c.success, const Color(0xFF0E7A50));
      expect(c.successBg, const Color(0xFFE2F4EB));
      expect(c.danger, const Color(0xFFC42B2B));
      expect(c.dangerBg, const Color(0xFFFCEBEB));
      expect(c.warning, const Color(0xFF8F5600));
      expect(c.warningBg, const Color(0xFFFFF1DB));
    });
  });

  group('AppColors.dark', () {
    const c = AppColors.dark;

    test('neutrals match the design', () {
      expect(c.bg, const Color(0xFF0F1115));
      expect(c.surface, const Color(0xFF171A21));
      expect(c.surface2, const Color(0xFF1D2129));
      expect(c.surface3, const Color(0xFF262B35));
      expect(c.text, const Color(0xFFF2F3F5));
      expect(c.text2, const Color(0xFFB6BCC8));
      expect(c.text3, const Color(0xFF9198A6));
      expect(c.border, const Color.fromRGBO(255, 255, 255, .08));
      expect(c.border2, const Color.fromRGBO(255, 255, 255, .16));
      expect(c.inverse, const Color(0xFFF2F3F5));
      expect(c.onInverse, const Color(0xFF14161B));
      expect(c.scrim, const Color.fromRGBO(0, 0, 0, .62));
    });

    test('status colors match the design', () {
      expect(c.success, const Color(0xFF46D494));
      expect(c.successBg, const Color.fromRGBO(70, 212, 148, .12));
      expect(c.danger, const Color(0xFFFF8A8A));
      expect(c.dangerBg, const Color.fromRGBO(255, 138, 138, .12));
      expect(c.warning, const Color(0xFFFFC266));
      expect(c.warningBg, const Color.fromRGBO(255, 194, 102, .12));
    });
  });

  group('GameColors', () {
    test('accent fills and soft tints are the same in both themes', () {
      for (final game in Game.values) {
        expect(GameColors.light.of(game).acc, GameColors.dark.of(game).acc);
        expect(GameColors.light.of(game).soft, GameColors.dark.of(game).soft);
      }
    });

    test('values match the design', () {
      final expected = {
        Game.genshin: (
          const Color(0xFF4A90E2),
          const Color(0xFF1F62B0),
          const Color(0xFF8DBDF3),
          const Color.fromRGBO(74, 144, 226, .14),
        ),
        Game.starRail: (
          const Color(0xFF8B7CF6),
          const Color(0xFF5A46D4),
          const Color(0xFFBBB0FB),
          const Color.fromRGBO(139, 124, 246, .15),
        ),
        Game.zzz: (
          const Color(0xFFF5C518),
          const Color(0xFF735C00),
          const Color(0xFFF5C518),
          const Color.fromRGBO(245, 197, 24, .18),
        ),
        Game.hi3: (
          const Color(0xFFE94B6A),
          const Color(0xFFB32448),
          const Color(0xFFF58CA1),
          const Color.fromRGBO(233, 75, 106, .13),
        ),
      };
      for (final MapEntry(key: game, value: v) in expected.entries) {
        expect(GameColors.light.of(game).acc, v.$1, reason: '$game acc');
        expect(GameColors.light.of(game).accInk, v.$2, reason: '$game ink L');
        expect(GameColors.dark.of(game).accInk, v.$3, reason: '$game ink D');
        expect(GameColors.light.of(game).soft, v.$4, reason: '$game soft');
      }
    });
  });

  group('AppSpacing and AppRadius', () {
    test('spacing follows the 4-pt scale', () {
      expect(
        [
          AppSpacing.s4,
          AppSpacing.s8,
          AppSpacing.s12,
          AppSpacing.s16,
          AppSpacing.s20,
          AppSpacing.s24,
          AppSpacing.s32,
          AppSpacing.s40,
          AppSpacing.s56,
        ],
        [4, 8, 12, 16, 20, 24, 32, 40, 56],
      );
      expect(AppSpacing.gutter, 20);
      expect(AppSpacing.cardGap, 12);
    });

    test('radius values match the design', () {
      expect(AppRadius.code, 8);
      expect(AppRadius.iconTile, 12);
      expect(AppRadius.input, 14);
      expect(AppRadius.banner, 18);
      expect(AppRadius.tile, 20);
      expect(AppRadius.widget, 22);
      expect(AppRadius.hero, 24);
      expect(AppRadius.dialog, 28);
      expect(AppRadius.illustration, 32);
      expect(AppRadius.pill, 999);
    });
  });

  group('AppTextStyles', () {
    void expectStyle(
      TextStyle s, {
      required double size,
      required double line,
      required FontWeight weight,
      double tracking = 0,
    }) {
      expect(s.fontFamily, 'Inter');
      expect(s.fontSize, size);
      expect(s.height, closeTo(line / size, 1e-9));
      expect(s.fontWeight, weight);
      expect(s.letterSpacing ?? 0, closeTo(tracking, 1e-9));
    }

    test('type scale matches the design', () {
      expectStyle(
        AppTextStyles.display,
        size: 34,
        line: 38,
        weight: FontWeight.w700,
        tracking: -1.02,
      );
      expectStyle(
        AppTextStyles.headline,
        size: 28,
        line: 34,
        weight: FontWeight.w700,
        tracking: -0.56,
      );
      expectStyle(
        AppTextStyles.titleL,
        size: 22,
        line: 28,
        weight: FontWeight.w700,
      );
      expectStyle(
        AppTextStyles.titleM,
        size: 17,
        line: 22,
        weight: FontWeight.w700,
      );
      expectStyle(
        AppTextStyles.bodyL,
        size: 16,
        line: 24,
        weight: FontWeight.w400,
      );
      expectStyle(
        AppTextStyles.bodyM,
        size: 15,
        line: 22,
        weight: FontWeight.w400,
      );
      expectStyle(
        AppTextStyles.label,
        size: 13,
        line: 18,
        weight: FontWeight.w600,
      );
      expectStyle(
        AppTextStyles.caption,
        size: 12,
        line: 16,
        weight: FontWeight.w500,
      );
      expectStyle(
        AppTextStyles.overline,
        size: 11,
        line: 16,
        weight: FontWeight.w600,
        tracking: 0.88,
      );
    });

    test('tabular() turns on tabular figures', () {
      final s = AppTextStyles.tabular(AppTextStyles.display);
      expect(s.fontFeatures, contains(const FontFeature.tabularFigures()));
      expect(s.fontSize, AppTextStyles.display.fontSize);
    });
  });

  group('AppDurations', () {
    test('motion timings match the design', () {
      expect(AppDurations.ringFill, const Duration(milliseconds: 700));
      expect(AppDurations.countUp, const Duration(milliseconds: 500));
      expect(AppDurations.heroTransition, const Duration(milliseconds: 350));
      expect(AppDurations.gameSwitch, const Duration(milliseconds: 250));
      expect(AppDurations.toggle, const Duration(milliseconds: 220));
      expect(AppDurations.checkDraw, const Duration(milliseconds: 300));
      expect(AppDurations.shimmer, const Duration(milliseconds: 1200));
      expect(AppDurations.reducedMotion, const Duration(milliseconds: 150));
      expect(AppDurations.snackbar, const Duration(seconds: 4));
      expect(AppDurations.snackbarWithAction, const Duration(seconds: 6));
    });
  });
}
