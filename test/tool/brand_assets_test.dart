@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/design_system/components/app_mark.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/home_widgets/data/widget_labels.dart';
import 'package:hoyo_aio/features/home_widgets/domain/home_widget_repositories.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot_builder.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/widgets/widget_preview.dart';
import 'package:material_ui/material_ui.dart';

import '../features/home_widgets/_support/widget_fixtures.dart';
import '../features/home_widgets/_support/widget_overrides.dart';

const _brandDir = '../../assets/brand';
const _previewDir = '../../android/app/src/main/res/drawable-nodpi';
const _iconSize = 1024.0;
const _iconMarkScale = 0.667;
const _previewPixelRatio = 3.0;

Future<void> _render(
  WidgetTester tester,
  Widget child, {
  required Size size,
  required String path,
  double pixelRatio = 1,
}) async {
  final output = size * pixelRatio;
  tester.view
    ..physicalSize = output
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      home: ColoredBox(
        color: const Color(0x00000000),
        child: Center(
          child: RepaintBoundary(
            child: SizedBox.fromSize(
              size: output,
              child: FittedBox(
                child: SizedBox.fromSize(size: size, child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 2));
  await expectLater(find.byType(RepaintBoundary).last, matchesGoldenFile(path));
}

void main() {
  testWidgets('app icon, full square', (tester) async {
    await _render(
      tester,
      const AppMark(size: _iconSize, rounded: false),
      size: const Size.square(_iconSize),
      path: '$_brandDir/icon.png',
    );
  });

  testWidgets('app icon, adaptive foreground', (tester) async {
    await _render(
      tester,
      const SizedBox.square(
        dimension: _iconSize,
        child: Center(child: AppMarkGlyph(size: _iconSize * _iconMarkScale)),
      ),
      size: const Size.square(_iconSize),
      path: '$_brandDir/icon_foreground.png',
    );
  });

  final labels = widgetLabels(lookupAppLocalizations(const Locale('en')));
  final snapshot = WidgetSnapshotBuilder.build(
    notes: allNotes,
    checkInToday: [record(Game.genshin, CheckInResult.claimed)],
    day: '2026-11-21',
    checkInTotal: 3,
    widgets: const [],
    labels: labels,
    now: fetchedAt,
  );
  const previewSizes = {
    HomeWidgetSize.small: Size(170, 80),
    HomeWidgetSize.medium: Size(170, 170),
    HomeWidgetSize.large: Size(350, 170),
  };
  for (final MapEntry(key: size, value: box) in previewSizes.entries) {
    testWidgets('widget picker preview ${size.name}', (tester) async {
      await _render(
        tester,
        SizedBox.fromSize(
          size: box,
          child: WidgetPreview(
            snapshot: snapshot,
            size: size,
            config: config(size: size.name),
            now: widgetNow,
          ),
        ),
        size: box,
        pixelRatio: _previewPixelRatio,
        path: '$_previewDir/widget_preview_${size.name}.png',
      );
    });
  }
}
