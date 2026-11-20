import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/app_colors.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/app_elevation.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/game_colors.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('AppTheme', () {
    test('light theme uses light tokens, lime primary and Inter', () {
      final theme = AppTheme.light();
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, BrandColors.lime);
      expect(theme.colorScheme.onPrimary, BrandColors.ink);
      expect(theme.scaffoldBackgroundColor, AppColors.light.bg);
      expect(theme.colorScheme.surface, AppColors.light.surface);
      expect(theme.colorScheme.onSurface, AppColors.light.text);
      expect(theme.colorScheme.error, AppColors.light.danger);
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
      expect(theme.textTheme.bodyMedium?.color, AppColors.light.text);
      expect(theme.extension<AppColors>(), same(AppColors.light));
      expect(theme.extension<GameColors>(), same(GameColors.light));
      expect(theme.extension<AppElevation>(), same(AppElevation.light));
    });

    test('dark theme uses dark tokens', () {
      final theme = AppTheme.dark();
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, BrandColors.lime);
      expect(theme.scaffoldBackgroundColor, AppColors.dark.bg);
      expect(theme.textTheme.bodyMedium?.color, AppColors.dark.text);
      expect(theme.extension<AppColors>(), same(AppColors.dark));
      expect(theme.extension<AppElevation>()?.card, isEmpty);
    });

    test('type scale maps onto TextTheme slots', () {
      final t = AppTheme.light().textTheme;
      expect(t.displaySmall?.fontSize, 34);
      expect(t.headlineMedium?.fontSize, 28);
      expect(t.titleLarge?.fontSize, 22);
      expect(t.titleMedium?.fontSize, 17);
      expect(t.bodyLarge?.fontSize, 16);
      expect(t.bodyMedium?.fontSize, 15);
      expect(t.labelLarge?.fontSize, 13);
      expect(t.bodySmall?.fontSize, 12);
      expect(t.labelSmall?.fontSize, 11);
    });

    test('custom accent replaces primary with a readable on-color', () {
      const blue = Color(0xFF1F62B0);
      final theme = AppTheme.light(accent: blue);
      expect(theme.colorScheme.primary, blue);
      expect(theme.colorScheme.onPrimary, const Color(0xFFFFFFFF));
      expect(theme.scaffoldBackgroundColor, AppColors.light.bg);
    });

    test('dynamic scheme only replaces the primary family', () {
      final dynamicScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF006A60),
      );
      final theme = AppTheme.light(dynamicScheme: dynamicScheme);
      expect(theme.colorScheme.primary, dynamicScheme.primary);
      expect(theme.colorScheme.onPrimary, dynamicScheme.onPrimary);
      expect(theme.colorScheme.surface, AppColors.light.surface);
      expect(theme.extension<GameColors>(), same(GameColors.light));
    });
  });

  group('ThemeExtension.lerp', () {
    test('AppColors lerps between light and dark', () {
      const a = AppColors.light;
      const b = AppColors.dark;
      expect(a.lerp(b, 0).bg, a.bg);
      expect(a.lerp(b, 1).bg, b.bg);
      expect(a.lerp(b, .5).bg, Color.lerp(a.bg, b.bg, .5));
      expect(a.lerp(null, .5), same(a));
    });

    test('GameColors lerps accent ink', () {
      const a = GameColors.light;
      const b = GameColors.dark;
      expect(a.lerp(b, 1).of(Game.genshin).accInk, b.of(Game.genshin).accInk);
      expect(a.lerp(b, 0).of(Game.genshin).accInk, a.of(Game.genshin).accInk);
    });

    test('AppElevation snaps to the target past halfway', () {
      expect(AppElevation.light.lerp(AppElevation.dark, .6).card, isEmpty);
      expect(
        AppElevation.light.lerp(AppElevation.dark, .4).card,
        AppElevation.light.card,
      );
    });
  });

  group('ThemeExtension.copyWith', () {
    test('AppColors replaces only the given field', () {
      const red = Color(0xFFFF0000);
      final c = AppColors.light.copyWith(bg: red);
      expect(c.bg, red);
      expect(c.text, AppColors.light.text);
      expect(AppColors.light.copyWith().scrim, AppColors.light.scrim);
    });

    test('GameColors replaces only the given game', () {
      const accent = GameAccent(
        acc: Color(0xFF000001),
        accInk: Color(0xFF000002),
        soft: Color(0xFF000003),
      );
      final g = GameColors.light.copyWith(zzz: accent);
      expect(g.of(Game.zzz), same(accent));
      expect(g.of(Game.genshin), same(GameColors.light.genshin));
      expect(GameColors.light.copyWith().hi3, same(GameColors.light.hi3));
    });

    test('AppElevation replaces only the given level', () {
      final e = AppElevation.light.copyWith(card: const []);
      expect(e.card, isEmpty);
      expect(e.dialog, AppElevation.light.dialog);
      expect(AppElevation.light.copyWith().card, AppElevation.light.card);
    });
  });

  testWidgets('context extensions read the active theme', (tester) async {
    late AppColors colors;
    late AppElevation elevation;
    late TextTheme textStyles;
    late Color genshinInk;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) {
            colors = context.colors;
            elevation = context.elevation;
            textStyles = context.textStyles;
            genshinInk = context.gameAccent(Game.genshin).accInk;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(colors, same(AppColors.dark));
    expect(elevation, same(AppElevation.dark));
    expect(textStyles.bodyMedium?.color, AppColors.dark.text);
    expect(genshinInk, GameColors.dark.of(Game.genshin).accInk);
  });
}
