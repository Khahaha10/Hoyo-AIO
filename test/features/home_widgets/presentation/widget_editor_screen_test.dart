import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_slider.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/home_widgets/data/widget_config_repository_impl.dart';
import 'package:hoyo_aio/features/home_widgets/domain/home_widget_repositories.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/providers/widget_sync_provider.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/widget_editor_screen.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/widgets/widget_preview.dart';
import 'package:material_ui/material_ui.dart';

import '../_support/pump_widget_screen.dart';
import '../_support/widget_fixtures.dart';
import '../_support/widget_overrides.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

class _Harness {
  _Harness(this.container, this.configs, this.bridge);

  final ProviderContainer container;
  final FakeWidgetConfigRepository configs;
  final FakeHomeWidgetBridge bridge;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  HomeWidgetSize size = HomeWidgetSize.medium,
  List<WidgetConfigSnapshot> existing = const [],
}) async {
  final configs = FakeWidgetConfigRepository(existing);
  final bridge = FakeHomeWidgetBridge();
  final container = ProviderContainer(
    overrides: [
      ...widgetOverrides(bridge: bridge, configs: configs),
      clockTickProvider.overrideWith((_) => Stream.value(widgetNow)),
    ],
  );
  addTearDown(container.dispose);
  container
    ..listen(widgetConfigsProvider, (_, _) {})
    ..listen(widgetSyncProvider, (_, _) {});
  await tester.runAsync(() async {
    await container.read(widgetConfigsProvider.future);
  });
  final router = await pumpRouted(
    tester,
    container: container,
    size: const Size(1080, 6000),
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: '/edit',
        builder: (_, _) => WidgetEditorScreen(widgetId: 7, size: size),
      ),
    ],
  );
  unawaitedPush(router);
  await _settle(tester);
  return _Harness(container, configs, bridge);
}

void unawaitedPush(GoRouter router) => router.push<void>('/edit').ignore();

Future<void> _tapSave(WidgetTester tester) async {
  await tester.ensureVisible(find.text(_l10n.widgetEditorSave));
  await tester.tap(find.text(_l10n.widgetEditorSave));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  testWidgets('shows title, size badge and a live preview', (tester) async {
    await _pump(tester);

    expect(find.text(_l10n.widgetEditorTitle), findsOneWidget);
    expect(find.text(_l10n.widgetsMediumTitle), findsOneWidget);
    expect(find.byType(WidgetPreview), findsOneWidget);
    expect(find.text('Tester1 · Genshin Impact'), findsOneWidget);
  });

  testWidgets('saves default draft with the role account and pops', (
    tester,
  ) async {
    final harness = await _pump(tester);

    await _tapSave(tester);

    final (saved, accountId) = harness.configs.saved.single;
    expect(saved.widgetId, 7);
    expect(saved.size, 'medium');
    expect(saved.roleId, genshinRole.id);
    expect(saved.theme, 'system');
    expect(accountId, testAccountId);
    expect(find.text('home'), findsOneWidget);
    expect(find.text(_l10n.widgetEditorSaved), findsOneWidget);
  });

  testWidgets('theme, accent, font and opacity controls update the draft', (
    tester,
  ) async {
    final harness = await _pump(tester);

    await tester.tap(find.text(_l10n.widgetThemeDark));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(_l10n.widgetAccentLime));
    await tester.pump();
    await tester.ensureVisible(find.text('L'));
    await tester.tap(find.text('L'));
    await tester.pump();
    tester.widget<AppSlider>(find.byType(AppSlider)).onChanged!(0.5);
    await tester.pump();
    expect(find.text('50%'), findsOneWidget);
    await _tapSave(tester);

    final saved = harness.configs.saved.single.$1;
    expect(saved.theme, 'dark');
    expect(saved.accent, 'lime');
    expect(saved.fontSize, 'large');
    expect(saved.opacity, 0.5);
  });

  testWidgets('saving publishes a snapshot with the new widget config', (
    tester,
  ) async {
    final harness = await _pump(tester);
    final before = harness.bridge.published.length;

    await tester.tap(find.text(_l10n.widgetThemeClear));
    await tester.pump();
    await _tapSave(tester);
    await _settle(tester);

    expect(harness.bridge.published.length, greaterThan(before));
    expect(harness.bridge.published.last.widgets.single.theme, 'clear');
  });

  testWidgets('starts from the stored config of the widget', (tester) async {
    final harness = await _pump(
      tester,
      existing: [config(roleId: zzzRole.id, accent: 'starRail')],
    );

    expect(find.text('Tester3 · Zenless Zone Zero'), findsOneWidget);
    await _tapSave(tester);

    expect(harness.configs.saved.single.$1.accent, 'starRail');
  });

  testWidgets('visible item chips toggle up to three slots', (tester) async {
    final harness = await _pump(tester);
    expect(find.text(_l10n.widgetEditorVisibleItems(3, 3)), findsOneWidget);

    await tester.ensureVisible(find.text('Realm').last);
    await tester.tap(find.text('Realm').last);
    await tester.pump();
    expect(find.text(_l10n.widgetEditorVisibleItems(2, 3)), findsOneWidget);

    await tester.tap(find.text(_l10n.genshinTransformer));
    await tester.pump();
    await tester.tap(find.text(_l10n.genshinExpeditions));
    await tester.pump();
    expect(find.text(_l10n.widgetEditorVisibleItems(3, 3)), findsOneWidget);
    await _tapSave(tester);

    expect(harness.configs.saved.single.$1.visibleItems, [
      'commissions',
      'weeklyBosses',
      'transformer',
    ]);
  });

  testWidgets('hides visible items for the small size', (tester) async {
    await _pump(tester, size: HomeWidgetSize.small);

    expect(find.text(_l10n.widgetEditorVisibleItems(3, 3)), findsNothing);
    expect(find.text(_l10n.widgetsSmallTitle), findsOneWidget);
  });

  testWidgets('role row switches the role and resets visible items', (
    tester,
  ) async {
    final harness = await _pump(
      tester,
      existing: [
        config(visibleItems: const ['realm']),
      ],
    );

    await tester.ensureVisible(find.text('Tester1 · Genshin Impact'));
    await tester.tap(find.text('Tester1 · Genshin Impact'));
    await _settle(tester);
    await tester.tap(find.textContaining('Tester2').last);
    await _settle(tester);
    await _tapSave(tester);

    final saved = harness.configs.saved.single.$1;
    expect(saved.roleId, starRailRole.id);
    expect(saved.visibleItems, isEmpty);
  });

  testWidgets('back button returns without saving', (tester) async {
    final harness = await _pump(tester);

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is AppIconButton && w.semanticLabel == _l10n.commonBack,
      ),
    );
    await _settle(tester);

    expect(find.text('home'), findsOneWidget);
    expect(harness.configs.saved, isEmpty);
  });
}
