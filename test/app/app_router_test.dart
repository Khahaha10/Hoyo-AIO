import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/app.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/app/router/app_router.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/gallery/gallery_screen.dart';

import '../helpers/app_overrides.dart';

Future<GoRouter> _pump(WidgetTester tester, Flavor flavor) async {
  await tester.pumpWidget(withAppScope(App(flavor: flavor), flavor: flavor));
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(tester.element(find.byType(App)));
  return container.read(appRouterProvider);
}

void main() {
  group('appRouter', () {
    testWidgets('dev can open the component gallery', (tester) async {
      final router = await _pump(tester, Flavor.dev);
      router.go(AppRoutes.gallery);
      await tester.pumpAndSettle();
      expect(find.byType(GalleryScreen), findsOneWidget);
    });

    testWidgets('prod has no gallery route', (tester) async {
      final router = await _pump(tester, Flavor.prod);
      router.go(AppRoutes.gallery);
      await tester.pumpAndSettle();
      expect(find.byType(GalleryScreen), findsNothing);
    });
  });
}
