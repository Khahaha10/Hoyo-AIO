import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/app_segmented_control.dart';
import 'package:hoyo_aio/core/design_system/components/app_slider.dart';
import 'package:hoyo_aio/core/design_system/components/app_swatch_picker.dart';
import 'package:hoyo_aio/core/design_system/components/game_switcher_chip.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/app_colors.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/game_colors.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_themed.dart';

void main() {
  group('GameSwitcherChip', () {
    testWidgets('selected uses soft tint, accent border and text color', (
      tester,
    ) async {
      var taps = 0;
      await pumpThemed(
        tester,
        GameSwitcherChip(
          game: Game.starRail,
          label: 'Star Rail',
          selected: true,
          onTap: () => taps++,
        ),
      );
      final chip = tester.widget<Container>(
        find.byKey(GameSwitcherChip.chipKey),
      );
      final d = chip.decoration! as BoxDecoration;
      expect(d.color, GameColors.light.starRail.soft);
      expect((d.border! as Border).top.color, GameColors.light.starRail.acc);
      expect(
        tester.widget<Text>(find.text('Star Rail')).style?.color,
        AppColors.light.text,
      );
      expect(tester.getSize(find.byKey(GameSwitcherChip.chipKey)).height, 36);
      expect(tester.getSize(find.byType(GameSwitcherChip)).height, 44);
      await tester.tap(find.byType(GameSwitcherChip));
      expect(taps, 1);
      expect(
        tester
            .getSemantics(find.byType(GameSwitcherChip))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
    });

    testWidgets('unselected uses surface and text-2', (tester) async {
      await pumpThemed(
        tester,
        GameSwitcherChip(
          game: Game.genshin,
          label: 'Genshin',
          selected: false,
          onTap: () {},
        ),
      );
      final d =
          tester
                  .widget<Container>(find.byKey(GameSwitcherChip.chipKey))
                  .decoration!
              as BoxDecoration;
      expect(d.color, AppColors.light.surface);
      expect(
        tester.widget<Text>(find.text('Genshin')).style?.color,
        AppColors.light.text2,
      );
    });
  });

  group('AppBadge', () {
    testWidgets('is 24 tall and uses status colors', (tester) async {
      await pumpThemed(
        tester,
        const AppBadge(label: 'Stale', variant: AppBadgeVariant.warning),
      );
      expect(tester.getSize(find.byType(AppBadge)).height, 24);
      final d =
          tester.widget<Container>(find.byType(Container).first).decoration!
              as BoxDecoration;
      expect(d.color, AppColors.light.warningBg);
      expect(
        tester.widget<Text>(find.text('Stale')).style?.color,
        AppColors.light.warning,
      );
    });

    testWidgets('neutral has a border on surface-2', (tester) async {
      await pumpThemed(tester, const AppBadge(label: '+1 every 8 min'));
      final d =
          tester.widget<Container>(find.byType(Container).first).decoration!
              as BoxDecoration;
      expect(d.color, AppColors.light.surface2);
      expect((d.border! as Border).top.color, AppColors.light.border);
    });
  });

  group('AppSegmentedControl', () {
    testWidgets('marks the selected option and reports taps', (tester) async {
      String? picked;
      await pumpThemed(
        tester,
        AppSegmentedControl<String>(
          options: const [
            SegmentOption(value: 'system', label: 'System'),
            SegmentOption(value: 'light', label: 'Light'),
            SegmentOption(value: 'dark', label: 'Dark'),
          ],
          selected: 'system',
          onChanged: (v) => picked = v,
        ),
      );
      expect(
        tester.widget<Text>(find.text('System')).style?.color,
        AppColors.light.text,
      );
      expect(
        tester.widget<Text>(find.text('Dark')).style?.color,
        AppColors.light.text2,
      );
      await tester.tap(find.text('Dark'));
      expect(picked, 'dark');
      expect(
        tester.getSemantics(find.text('System')).flagsCollection.isChecked,
        CheckedState.isTrue,
      );
      expect(
        tester.getSize(find.byType(AppSegmentedControl<String>)).height,
        44,
      );
    });
  });

  group('AppSwatchPicker', () {
    testWidgets('selects a swatch and labels each for screen readers', (
      tester,
    ) async {
      String? picked;
      await pumpThemed(
        tester,
        AppSwatchPicker<String>(
          options: const [
            SwatchOption(
              value: 'match',
              label: 'Match game',
              colors: [
                Color(0xFF4A90E2),
                Color(0xFF8B7CF6),
                Color(0xFFF5C518),
                Color(0xFFE94B6A),
              ],
            ),
            SwatchOption(
              value: 'lime',
              label: 'Lime',
              colors: [Color(0xFFD2E843)],
            ),
          ],
          selected: 'match',
          onChanged: (v) => picked = v,
        ),
      );
      await tester.tap(find.bySemanticsLabel('Lime'));
      expect(picked, 'lime');
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Match game'))
            .flagsCollection
            .isChecked,
        CheckedState.isTrue,
      );
    });
  });

  group('AppSlider', () {
    testWidgets('reports new values when dragged', (tester) async {
      double? value;
      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: AppSlider(
            value: 90,
            min: 50,
            max: 100,
            onChanged: (v) => value = v,
            semanticLabel: 'Stamina threshold',
          ),
        ),
      );
      await tester.drag(find.byType(AppSlider), const Offset(-200, 0));
      expect(value, isNotNull);
      expect(value, lessThan(90));
    });
  });
}
