import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/app/router/app_router.dart';
import 'package:hoyo_aio/core/design_system/gallery/gallery_screen.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

Future<GoRouter> _pump(WidgetTester tester, Flavor flavor) async {
  final router = buildAppRouter(flavor);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  group('buildAppRouter', () {
    testWidgets('dev opens the component gallery', (tester) async {
      await _pump(tester, Flavor.dev);
      expect(find.byType(GalleryScreen), findsOneWidget);
    });

    testWidgets('prod has no gallery route', (tester) async {
      final router = await _pump(tester, Flavor.prod);
      expect(find.byType(GalleryScreen), findsNothing);
      expect(
        router.configuration.routes.whereType<GoRoute>().map((r) => r.path),
        isNot(contains(AppRoutes.gallery)),
      );
      router.go(AppRoutes.gallery);
      await tester.pumpAndSettle();
      expect(find.byType(GalleryScreen), findsNothing);
    });
  });
}
