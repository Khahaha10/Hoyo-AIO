import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/design_system/components/app_checkbox.dart';
import 'package:hoyo_aio/core/design_system/components/app_toggle.dart';
import 'package:hoyo_aio/core/design_system/components/radio_option_card.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/app_colors.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_themed.dart';

void main() {
  group('AppToggle', () {
    testWidgets('has a 52x32 track inside a 44-tall hit area', (tester) async {
      await pumpThemed(
        tester,
        AppToggle(value: false, onChanged: (_) {}, semanticLabel: 'Alerts'),
      );
      expect(tester.getSize(find.byType(AppToggle)).height, 44);
      expect(
        tester.getSize(find.byKey(AppToggle.trackKey)),
        const Size(52, 32),
      );
    });

    testWidgets('flips the value on tap and reports toggled state', (
      tester,
    ) async {
      bool? next;
      await pumpThemed(
        tester,
        AppToggle(value: false, onChanged: (v) => next = v, semanticLabel: 'A'),
      );
      expect(
        tester.getSemantics(find.byType(AppToggle)).flagsCollection.isToggled,
        Tristate.isFalse,
      );
      await tester.tap(find.byType(AppToggle));
      expect(next, isTrue);
    });

    testWidgets('on state uses a lime track', (tester) async {
      await pumpThemed(
        tester,
        AppToggle(value: true, onChanged: (_) {}, semanticLabel: 'A'),
      );
      await tester.pumpAndSettle();
      final track = tester.widget<AnimatedContainer>(
        find.byKey(AppToggle.trackKey),
      );
      expect((track.decoration! as BoxDecoration).color, BrandColors.lime);
    });

    testWidgets('disabled ignores taps', (tester) async {
      await pumpThemed(
        tester,
        const AppToggle(value: true, onChanged: null, semanticLabel: 'Locked'),
      );
      await tester.tap(find.byType(AppToggle));
      expect(
        tester.getSemantics(find.byType(AppToggle)).flagsCollection.isEnabled,
        Tristate.isFalse,
      );
    });
  });

  group('AppCheckbox', () {
    testWidgets('is 24 with r8 inside a 44 hit area and toggles', (
      tester,
    ) async {
      bool? next;
      await pumpThemed(
        tester,
        AppCheckbox(
          value: false,
          onChanged: (v) => next = v,
          semanticLabel: 'x',
        ),
      );
      expect(tester.getSize(find.byType(AppCheckbox)), const Size(44, 44));
      expect(
        tester.getSize(find.byKey(AppCheckbox.boxKey)),
        const Size(24, 24),
      );
      await tester.tap(find.byType(AppCheckbox));
      expect(next, isTrue);
    });

    testWidgets('checked is lime with an ink check', (tester) async {
      await pumpThemed(
        tester,
        AppCheckbox(value: true, onChanged: (_) {}, semanticLabel: 'x'),
      );
      final box = tester.widget<Container>(find.byKey(AppCheckbox.boxKey));
      expect((box.decoration! as BoxDecoration).color, BrandColors.lime);
      final check = tester.widget<Icon>(find.byIcon(LucideIcons.check));
      expect(check.color, BrandColors.ink);
      expect(
        tester.getSemantics(find.byType(AppCheckbox)).flagsCollection.isChecked,
        CheckedState.isTrue,
      );
    });
  });

  group('RadioOptionCard', () {
    testWidgets('selected card has a 2px text-color border', (tester) async {
      var taps = 0;
      await pumpThemed(
        tester,
        RadioOptionCard(
          title: 'Paste Cookie',
          subtitle: 'Copy it from your browser.',
          icon: LucideIcons.cookie,
          selected: true,
          onTap: () => taps++,
        ),
      );
      final card = tester.widget<Container>(
        find.byKey(RadioOptionCard.cardKey),
      );
      final border = (card.decoration! as BoxDecoration).border! as Border;
      expect(border.top.width, 2);
      expect(border.top.color, AppColors.light.text);

      await tester.tap(find.byType(RadioOptionCard));
      expect(taps, 1);
      expect(
        tester
            .getSemantics(find.byType(RadioOptionCard))
            .flagsCollection
            .isChecked,
        CheckedState.isTrue,
      );
    });

    testWidgets('unselected card uses the light border', (tester) async {
      await pumpThemed(
        tester,
        RadioOptionCard(
          title: 'Paste Cookie',
          subtitle: 'Copy it from your browser.',
          icon: LucideIcons.cookie,
          selected: false,
          onTap: () {},
        ),
      );
      final card = tester.widget<Container>(
        find.byKey(RadioOptionCard.cardKey),
      );
      final border = (card.decoration! as BoxDecoration).border! as Border;
      expect(border.top.color, AppColors.light.border);
    });
  });
}
