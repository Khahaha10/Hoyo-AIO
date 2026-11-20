import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/app_colors.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_themed.dart';

BoxDecoration _decorationOf(WidgetTester tester, String label) {
  final container = tester.widget<Container>(
    find.ancestor(of: find.text(label), matching: find.byType(Container)).first,
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  group('AppButton', () {
    testWidgets('primary is 52 tall, lime with ink label, and taps', (
      tester,
    ) async {
      var taps = 0;
      await pumpThemed(
        tester,
        AppButton(label: 'Check In Now', onPressed: () => taps++),
      );

      expect(tester.getSize(find.byType(AppButton)).height, 52);
      expect(_decorationOf(tester, 'Check In Now').color, BrandColors.lime);
      expect(
        tester.widget<Text>(find.text('Check In Now')).style?.color,
        BrandColors.ink,
      );

      await tester.tap(find.byType(AppButton));
      expect(taps, 1);
    });

    testWidgets('primary pressed uses pressed lime and scales down', (
      tester,
    ) async {
      await pumpThemed(tester, AppButton(label: 'Go', onPressed: () {}));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AppButton)),
      );
      await tester.pumpAndSettle();
      expect(_decorationOf(tester, 'Go').color, BrandColors.limePressed);
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        0.97,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_decorationOf(tester, 'Go').color, BrandColors.lime);
    });

    testWidgets('disabled primary uses surface-3 and text-3', (tester) async {
      await pumpThemed(tester, const AppButton(label: 'Go', onPressed: null));

      expect(_decorationOf(tester, 'Go').color, AppColors.light.surface3);
      expect(
        tester.widget<Text>(find.text('Go')).style?.color,
        AppColors.light.text3,
      );
      final semantics = tester.getSemantics(find.byType(AppButton));
      expect(semantics.flagsCollection.isEnabled, Tristate.isFalse);
    });

    testWidgets('loading shows a spinner, keeps colors and ignores taps', (
      tester,
    ) async {
      var taps = 0;
      await pumpThemed(
        tester,
        AppButton(
          label: 'Checking In…',
          onPressed: () => taps++,
          isLoading: true,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(_decorationOf(tester, 'Checking In…').color, BrandColors.lime);
      await tester.tap(find.byType(AppButton));
      expect(taps, 0);
    });

    testWidgets('secondary has a border-2 outline on surface', (tester) async {
      await pumpThemed(
        tester,
        AppButton(
          label: 'Later',
          variant: AppButtonVariant.secondary,
          onPressed: () {},
        ),
      );

      final d = _decorationOf(tester, 'Later');
      expect(d.color, AppColors.light.surface);
      expect((d.border! as Border).top.color, AppColors.light.border2);
      expect(tester.getSize(find.byType(AppButton)).height, 52);
    });

    testWidgets('text variant is 44 tall with no fill', (tester) async {
      await pumpThemed(
        tester,
        AppButton(
          label: 'Skip',
          variant: AppButtonVariant.text,
          onPressed: () {},
          expand: false,
        ),
      );

      expect(tester.getSize(find.byType(AppButton)).height, 44);
      expect(_decorationOf(tester, 'Skip').color, isNull);
    });

    testWidgets('shows a leading icon when given', (tester) async {
      await pumpThemed(
        tester,
        AppButton(label: 'Add', icon: LucideIcons.plus, onPressed: () {}),
      );
      expect(find.byIcon(LucideIcons.plus), findsOneWidget);
    });

    testWidgets('exposes a button with its label to semantics', (tester) async {
      await pumpThemed(tester, AppButton(label: 'Continue', onPressed: () {}));
      expect(
        tester.getSemantics(find.byType(AppButton)),
        matchesSemantics(
          label: 'Continue',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
    });
  });

  group('AppIconButton', () {
    testWidgets('is a 44 circle with a label for screen readers', (
      tester,
    ) async {
      var taps = 0;
      await pumpThemed(
        tester,
        AppIconButton(
          icon: LucideIcons.refreshCw,
          semanticLabel: 'Refresh',
          onPressed: () => taps++,
        ),
      );

      expect(tester.getSize(find.byType(AppIconButton)), const Size(44, 44));
      expect(tester.getSemantics(find.byType(AppIconButton)).label, 'Refresh');
      await tester.tap(find.byType(AppIconButton));
      expect(taps, 1);
    });
  });
}
