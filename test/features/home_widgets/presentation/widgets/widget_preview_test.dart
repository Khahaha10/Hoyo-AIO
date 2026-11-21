import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:hoyo_aio/core/design_system/tokens/widget_tokens.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/home_widgets/domain/home_widget_repositories.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot_builder.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/widgets/widget_preview.dart';
import 'package:material_ui/material_ui.dart';

import '../../_support/widget_fixtures.dart';
import '../../_support/widget_overrides.dart';

Future<void> _pump(
  WidgetTester tester, {
  required HomeWidgetSize size,
  WidgetConfigSnapshot? config,
  int? roleId,
  WidgetSnapshot? snapshot,
  DateTime? now,
  Brightness brightness = Brightness.light,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(platformBrightness: brightness),
      child: Scaffold(
        body: Center(
          child: WidgetPreview(
            snapshot: snapshot ?? previewSnapshot(),
            size: size,
            config: config,
            roleId: roleId,
            now: now ?? widgetNow,
          ),
        ),
      ),
    ),
  ),
);

Color _background(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(WidgetPreview),
          matching: find.byType(Container),
        )
        .first,
  );
  return (container.decoration! as BoxDecoration).color!;
}

void main() {
  test('sizeOf matches the design cell sizes', () {
    expect(WidgetPreview.sizeOf(HomeWidgetSize.small), const Size(169, 80));
    expect(WidgetPreview.sizeOf(HomeWidgetSize.medium), const Size(169, 169));
    expect(WidgetPreview.sizeOf(HomeWidgetSize.large), const Size(350, 169));
  });

  testWidgets('small shows stamina counted up locally and the full time', (
    tester,
  ) async {
    await _pump(tester, size: HomeWidgetSize.small);

    expect(find.text('105/200', findRichText: true), findsOneWidget);
    expect(find.text('Full 23:20'), findsOneWidget);
  });

  testWidgets('small reads Full when stamina is capped', (tester) async {
    await _pump(tester, size: HomeWidgetSize.small, roleId: starRailRole.id);

    expect(find.text('240/240', findRichText: true), findsOneWidget);
    expect(find.text('Full'), findsOneWidget);
  });

  testWidgets('small reaches max once fullAt has passed', (tester) async {
    await _pump(
      tester,
      size: HomeWidgetSize.small,
      now: fetchedAt.add(const Duration(days: 1)),
    );

    expect(find.text('200/200', findRichText: true), findsOneWidget);
  });

  testWidgets('medium shows the first three Genshin items by default', (
    tester,
  ) async {
    await _pump(tester, size: HomeWidgetSize.medium, config: config());

    expect(find.text('Genshin'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('105'), findsOneWidget);
    expect(find.text('Realm'), findsOneWidget);
    expect(find.text('1,200'), findsOneWidget);
    expect(find.text('Commissions'), findsOneWidget);
    expect(find.text('2/4'), findsOneWidget);
    expect(find.text('Weekly Bosses'), findsOneWidget);
    expect(find.text('Transformer'), findsNothing);
  });

  testWidgets('medium follows visible items in the chosen order', (
    tester,
  ) async {
    await _pump(
      tester,
      size: HomeWidgetSize.medium,
      config: config(visibleItems: const ['transformer', 'expeditions']),
    );

    expect(find.text('Transformer'), findsOneWidget);
    expect(find.text('15:00'), findsOneWidget);
    expect(find.text('Expeditions'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('Realm'), findsNothing);
  });

  testWidgets('medium shows ready and all-back states once times pass', (
    tester,
  ) async {
    await _pump(
      tester,
      size: HomeWidgetSize.medium,
      config: config(visibleItems: const ['transformer', 'expeditions']),
      now: fetchedAt.add(const Duration(hours: 7)),
    );

    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('3/3'), findsOneWidget);
  });

  testWidgets('medium renders ZZZ states and falls back to raw keys', (
    tester,
  ) async {
    await _pump(
      tester,
      size: HomeWidgetSize.medium,
      config: config(roleId: zzzRole.id),
    );

    expect(find.text('ZZZ'), findsOneWidget);
    expect(find.text('engagement'), findsOneWidget);
    expect(find.text('300/400'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Revenue ready'), findsOneWidget);
  });

  testWidgets('large lists every role with bars and the check-in footer', (
    tester,
  ) async {
    await _pump(tester, size: HomeWidgetSize.large);

    expect(find.text('HoYo AIO'), findsOneWidget);
    expect(find.text('Updated 10:00'), findsOneWidget);
    expect(find.text('Resin'), findsOneWidget);
    expect(find.text('Power'), findsOneWidget);
    expect(find.text('Battery'), findsOneWidget);
    expect(find.text('105/200'), findsOneWidget);
    expect(find.text('240/240'), findsOneWidget);
    expect(find.text('66/240'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
    expect(find.text('Checked in to 1 of 3 games'), findsOneWidget);
  });

  testWidgets('large without roles uses generatedAt and hides check-in', (
    tester,
  ) async {
    final empty = WidgetSnapshotBuilder.build(
      notes: const [],
      checkInToday: const [],
      day: '2026-11-21',
      checkInTotal: 0,
      widgets: const [],
      labels: testLabels,
      now: fetchedAt,
    );

    await _pump(tester, size: HomeWidgetSize.large, snapshot: empty);

    expect(find.text('Updated 10:00'), findsOneWidget);
    expect(find.textContaining('Checked in'), findsNothing);
  });

  testWidgets('small without roles renders an empty card', (tester) async {
    final empty = WidgetSnapshotBuilder.build(
      notes: const [],
      checkInToday: const [],
      day: '2026-11-21',
      checkInTotal: 0,
      widgets: const [],
      labels: testLabels,
      now: fetchedAt,
    );

    await _pump(tester, size: HomeWidgetSize.small, snapshot: empty);

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('theme and opacity come from the config', (tester) async {
    await _pump(
      tester,
      size: HomeWidgetSize.small,
      config: config(theme: 'dark', opacity: 0.5),
    );

    final dark = Color(WidgetTokens.themes['dark']!['background']!);
    expect(_background(tester).a, closeTo(dark.a * 0.5, 0.01));
    expect(_background(tester).r, closeTo(dark.r, 0.01));
  });

  testWidgets('system theme follows the platform brightness', (tester) async {
    await _pump(
      tester,
      size: HomeWidgetSize.small,
      config: config(theme: 'system'),
      brightness: Brightness.dark,
    );

    final dark = Color(WidgetTokens.themes['dark']!['background']!);
    expect(_background(tester).r, closeTo(dark.r, 0.01));
  });

  testWidgets('no config uses the light palette at full opacity', (
    tester,
  ) async {
    await _pump(tester, size: HomeWidgetSize.large);

    expect(
      _background(tester),
      Color(WidgetTokens.themes['light']!['background']!),
    );
  });

  for (final accent in ['lime', 'neutral', 'starRail', 'unknown'])
    for (final fontSize in ['small', 'large'])
      testWidgets('renders accent $accent with $fontSize text', (tester) async {
        await _pump(
          tester,
          size: HomeWidgetSize.medium,
          config: config(accent: accent, fontSize: fontSize),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('105'), findsOneWidget);
      });
}
