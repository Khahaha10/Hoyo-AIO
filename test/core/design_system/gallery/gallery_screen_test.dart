import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/design_system/gallery/gallery_screen.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/app_colors.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pumpGallery(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light(), home: const GalleryScreen()),
  );
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _scrollThrough(WidgetTester tester) async {
  final list = find.byType(Scrollable).first;
  for (var i = 0; i < 40; i++) {
    await tester.drag(list, const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  }
}

void main() {
  testWidgets('renders every section without exceptions', (tester) async {
    await _pumpGallery(tester);
    expect(find.text('Colors'), findsOneWidget);
    await _scrollThrough(tester);
    expect(find.text('Navigation'), findsOneWidget);
  });

  testWidgets('theme switch shows the dark tokens', (tester) async {
    await _pumpGallery(tester);
    await tester.tap(find.bySemanticsLabel('Dark theme'));
    await tester.pump(const Duration(seconds: 1));
    final context = tester.element(find.text('Colors'));
    expect(Theme.of(context).extension<AppColors>(), same(AppColors.dark));
  });

  testWidgets('1.3x text switch survives a full scroll', (tester) async {
    await _pumpGallery(tester);
    await tester.tap(find.bySemanticsLabel('Large text'));
    await tester.pump(const Duration(seconds: 1));
    final context = tester.element(find.text('Colors'));
    expect(MediaQuery.textScalerOf(context).scale(10), closeTo(13, 1e-9));
    await _scrollThrough(tester);
  });
}
