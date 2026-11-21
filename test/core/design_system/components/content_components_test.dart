import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/expedition_tile.dart';
import 'package:hoyo_aio/core/design_system/components/reward_day_cell.dart';
import 'package:hoyo_aio/core/design_system/components/stamina_ring_card.dart';
import 'package:hoyo_aio/core/design_system/components/stat_tile.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/app_colors.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/game_colors.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_themed.dart';

StaminaRingCard _ring({int current = 142, bool isStale = false}) =>
    StaminaRingCard(
      game: Game.genshin,
      current: current,
      max: 200,
      label: 'Original Resin',
      primaryText: 'Full in 3h 12m',
      secondaryText: 'at 21:40 today',
      badgeLabel: '+1 every 8 min',
      isStale: isStale,
    );

void main() {
  group('StaminaRingPainter', () {
    test('starts at 12 o\'clock and sweeps by fraction', () {
      expect(StaminaRingPainter.startAngle, -math.pi / 2);
      const painter = StaminaRingPainter(
        fraction: 0.71,
        track: Color(0xFF000000),
        fill: Color(0xFFFFFFFF),
      );
      expect(painter.sweepAngle, closeTo(2 * math.pi * 0.71, 1e-9));
    });

    test('clamps fraction into 0..1', () {
      const over = StaminaRingPainter(
        fraction: 1.4,
        track: Color(0xFF000000),
        fill: Color(0xFFFFFFFF),
      );
      expect(over.sweepAngle, closeTo(2 * math.pi, 1e-9));
    });
  });

  group('StaminaRingCard', () {
    testWidgets('animates the ring and count-up to the value', (tester) async {
      await pumpThemed(tester, SizedBox(width: 350, child: _ring()));
      final early = tester.widget<CustomPaint>(
        find.byKey(StaminaRingCard.ringKey),
      );
      expect((early.painter! as StaminaRingPainter).fraction, lessThan(0.71));

      await tester.pumpAndSettle();
      final done = tester.widget<CustomPaint>(
        find.byKey(StaminaRingCard.ringKey),
      );
      expect(
        (done.painter! as StaminaRingPainter).fraction,
        closeTo(.71, 1e-9),
      );
      expect(
        (done.painter! as StaminaRingPainter).fill,
        GameColors.light.genshin.acc,
      );
      expect(find.text('142'), findsOneWidget);
      expect(find.text('/ 200'), findsOneWidget);
      expect(find.text('ORIGINAL RESIN'), findsOneWidget);
      expect(find.byType(AppBadge), findsOneWidget);
    });

    testWidgets('jumps straight to the value when motion is reduced', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        SizedBox(width: 350, child: _ring()),
        disableAnimations: true,
      );
      await tester.pump();
      final ring = tester.widget<CustomPaint>(
        find.byKey(StaminaRingCard.ringKey),
      );
      expect(
        (ring.painter! as StaminaRingPainter).fraction,
        closeTo(.71, 1e-9),
      );
      expect(find.text('142'), findsOneWidget);
    });

    testWidgets('stale state greys the ring at half opacity', (tester) async {
      await pumpThemed(
        tester,
        SizedBox(width: 350, child: _ring(isStale: true)),
      );
      await tester.pumpAndSettle();
      final ring = tester.widget<CustomPaint>(
        find.byKey(StaminaRingCard.ringKey),
      );
      expect((ring.painter! as StaminaRingPainter).fill, AppColors.light.text3);
      final opacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.byKey(StaminaRingCard.ringKey),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.5);
    });

    testWidgets('reads as one sentence for screen readers', (tester) async {
      await pumpThemed(tester, SizedBox(width: 350, child: _ring()));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.byType(StaminaRingCard)).label,
        'Original Resin, 142 / 200. Full in 3h 12m. at 21:40 today',
      );
    });
  });

  group('StatTile', () {
    Widget tile() => const SizedBox(
      width: 169,
      child: StatTile(
        game: Game.genshin,
        icon: LucideIcons.coins,
        label: 'Realm Currency',
        value: '1,840',
        suffix: '/2,400',
        progress: 0.77,
        note: 'Full in 9h',
      ),
    );

    testWidgets('is at least 112 tall and shows its parts', (tester) async {
      await pumpThemed(tester, tile());
      expect(
        tester.getSize(find.byType(StatTile)).height,
        greaterThanOrEqualTo(112),
      );
      expect(find.text('Realm Currency'), findsOneWidget);
      expect(find.text('Full in 9h'), findsOneWidget);
      final bar = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(bar.widthFactor, 0.77);
    });

    testWidgets('survives 1.3x text scale without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: Scaffold(body: Center(child: tile())),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('ExpeditionTile', () {
    testWidgets('shows the initial avatar and a countdown', (tester) async {
      await pumpThemed(
        tester,
        const ExpeditionTile(
          game: Game.genshin,
          name: 'Xiangling',
          subtitle: 'Expedition',
          trailingText: '2h 14m',
          isDone: false,
          doneLabel: 'Done',
        ),
      );
      expect(find.text('X'), findsOneWidget);
      expect(find.text('2h 14m'), findsOneWidget);
      expect(find.byIcon(LucideIcons.clock), findsOneWidget);
      expect(
        tester.getSize(find.byType(ExpeditionTile)).height,
        greaterThanOrEqualTo(60),
      );
    });

    testWidgets('done shows a success badge instead', (tester) async {
      await pumpThemed(
        tester,
        const ExpeditionTile(
          game: Game.genshin,
          name: 'Bennett',
          subtitle: 'Expedition',
          trailingText: '0m',
          isDone: true,
          doneLabel: 'Done',
        ),
      );
      final badge = tester.widget<AppBadge>(find.byType(AppBadge));
      expect(badge.variant, AppBadgeVariant.success);
      expect(find.text('0m'), findsNothing);
    });
  });

  group('RewardDayCell', () {
    Widget cell(RewardDayState state) => SizedBox(
      width: 56,
      child: RewardDayCell(
        day: 20,
        icon: LucideIcons.gem,
        quantity: '×20',
        state: state,
        missedLabel: 'Missed',
        semanticLabel: 'Day 20',
      ),
    );

    BoxDecoration decorationOf(WidgetTester tester) =>
        tester.widget<Container>(find.byKey(RewardDayCell.cellKey)).decoration!
            as BoxDecoration;

    testWidgets('today is lime with a halo', (tester) async {
      await pumpThemed(tester, cell(RewardDayState.today));
      final d = decorationOf(tester);
      expect(d.color, BrandColors.lime);
      expect(d.boxShadow, hasLength(2));
      expect(
        tester.getSize(find.byKey(RewardDayCell.cellKey)),
        const Size(56, 56),
      );
    });

    testWidgets('claimed is surface-2 with a check dot', (tester) async {
      await pumpThemed(tester, cell(RewardDayState.claimed));
      expect(decorationOf(tester).color, AppColors.light.surface2);
      expect(find.byKey(RewardDayCell.checkKey), findsOneWidget);
    });

    testWidgets('missed shows the missed label with a dashed outline', (
      tester,
    ) async {
      await pumpThemed(tester, cell(RewardDayState.missed));
      expect(find.text('Missed'), findsOneWidget);
      expect(find.text('×20'), findsNothing);
      expect(find.byKey(RewardDayCell.dashedKey), findsOneWidget);
    });

    testWidgets('upcoming uses surface', (tester) async {
      await pumpThemed(tester, cell(RewardDayState.upcoming));
      expect(decorationOf(tester).color, AppColors.light.surface);
    });

    testWidgets('claiming plays the bounce then settles at 1', (tester) async {
      await pumpThemed(tester, cell(RewardDayState.today));
      await pumpThemed(tester, cell(RewardDayState.claimed));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final mid = tester.widget<Transform>(find.byKey(RewardDayCell.scaleKey));
      expect(mid.transform.storage[0], isNot(1));
      await tester.pumpAndSettle();
      final end = tester.widget<Transform>(find.byKey(RewardDayCell.scaleKey));
      expect(end.transform.storage[0], closeTo(1, 1e-9));
    });
  });
}
