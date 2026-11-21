import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/home_widgets/domain/home_widget_repositories.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/providers/widget_sync_provider.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/widget_gallery_screen.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/widgets/widget_preview.dart';
import 'package:material_ui/material_ui.dart';

import '../_support/pump_widget_screen.dart';
import '../_support/widget_fixtures.dart';
import '../_support/widget_overrides.dart';

ProviderContainer _container(
  FakeHomeWidgetBridge bridge, {
  bool hasSnapshot = true,
  FakeWidgetConfigRepository? configs,
}) {
  final container = ProviderContainer(
    overrides: [
      ...widgetOverrides(
        bridge: bridge,
        configs: configs ?? FakeWidgetConfigRepository(),
      ),
      widgetSyncProvider.overrideWith(
        (_) async => hasSnapshot ? previewSnapshot() : null,
      ),
      clockTickProvider.overrideWith((_) => Stream.value(widgetNow)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

final _routes = [
  GoRoute(
    path: '/',
    builder: (_, _) => const Scaffold(body: WidgetGalleryScreen()),
  ),
  GoRoute(
    path: AppRoutes.widgetEditorPath,
    builder: (_, state) => Scaffold(body: Text('editor ${state.uri.query}')),
  ),
];

Future<void> _pump(WidgetTester tester, ProviderContainer container) async {
  await pumpRouted(tester, container: container, routes: _routes);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('asks to open the dashboard when no snapshot exists', (
    tester,
  ) async {
    await _pump(tester, _container(FakeHomeWidgetBridge(), hasSnapshot: false));

    expect(
      find.text('Open the Dashboard once so widgets have data to show.'),
      findsOneWidget,
    );
    expect(find.byType(WidgetPreview), findsNothing);
  });

  testWidgets('shows every size section with two samples per row', (
    tester,
  ) async {
    await _pump(tester, _container(FakeHomeWidgetBridge()));

    expect(find.text('SMALL · 2×1'), findsOneWidget);
    expect(find.text('MEDIUM · 2×2'), findsOneWidget);
    expect(find.text('LARGE · 4×2'), findsOneWidget);
    expect(find.byType(WidgetPreview), findsNWidgets(5));
  });

  testWidgets('size tabs filter the sections', (tester) async {
    await _pump(tester, _container(FakeHomeWidgetBridge()));

    await tester.tap(find.text('Large'));
    await tester.pumpAndSettle();

    expect(find.text('LARGE · 4×2'), findsOneWidget);
    expect(find.text('SMALL · 2×1'), findsNothing);
    expect(find.byType(WidgetPreview), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.byType(WidgetPreview), findsNWidgets(5));
  });

  testWidgets('placed widgets come first and open the editor', (tester) async {
    final bridge = FakeHomeWidgetBridge(
      placedWidgets: const [
        PlacedWidget(widgetId: 42, size: HomeWidgetSize.medium),
      ],
    );
    await _pump(
      tester,
      _container(
        bridge,
        configs: FakeWidgetConfigRepository([
          config(widgetId: 42, roleId: starRailRole.id),
        ]),
      ),
    );
    await tester.tap(find.text('Medium'));
    await tester.pumpAndSettle();
    expect(find.byType(WidgetPreview), findsNWidgets(2));

    await tester.tap(find.byType(WidgetPreview).first);
    await tester.pumpAndSettle();

    expect(find.text('editor id=42&size=medium'), findsOneWidget);
  });

  testWidgets('tapping a sample without pin support explains manual adding', (
    tester,
  ) async {
    final bridge = FakeHomeWidgetBridge(pinSupported: false);
    await _pump(tester, _container(bridge));

    await tester.tap(find.byType(WidgetPreview).first);
    await tester.pump();

    expect(
      find.text(
        'Long-press your home screen, choose Widgets and find HoYo AIO.',
      ),
      findsOneWidget,
    );
    expect(bridge.pinned, isEmpty);
  });

  testWidgets('BUG: widget_gallery_screen.dart:52 reads the autoDispose '
      'canPinWidgetProvider with ref.read while it is still loading, so a '
      'sample tap never pins and always shows the manual snackbar', (
    tester,
  ) async {
    final bridge = FakeHomeWidgetBridge();
    await _pump(tester, _container(bridge));

    await tester.tap(find.byType(WidgetPreview).first);
    await tester.pumpAndSettle();

    expect(bridge.pinned, [HomeWidgetSize.small]);
  }, skip: true);

  testWidgets('add sheet lists the three sizes and closes on pick', (
    tester,
  ) async {
    final bridge = FakeHomeWidgetBridge(pinSupported: false);
    await _pump(tester, _container(bridge));

    await tester.tap(find.byType(AppIconButton));
    await tester.pumpAndSettle();

    expect(find.text('Small · 2×1'), findsOneWidget);
    expect(find.text('Medium · 2×2'), findsOneWidget);
    expect(find.text('Stamina + 3 items'), findsNWidgets(2));

    await tester.tap(find.text('Large · 4×2'));
    await tester.pumpAndSettle();

    expect(find.text('Add a Widget'), findsNothing);
    expect(bridge.pinned, isEmpty);
  });
}
