import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/storage/cookie_vault.dart';
import 'package:hoyo_aio/core/storage/hoyolab_cookie.dart';
import 'package:hoyo_aio/features/home_widgets/data/widget_config_repository_impl.dart';
import 'package:hoyo_aio/features/home_widgets/domain/home_widget_repositories.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/providers/widget_sync_provider.dart';
import 'package:material_ui/material_ui.dart';

import '../../_support/widget_fixtures.dart';
import '../../_support/widget_overrides.dart';

const _fakeLtoken = 'v2_fakeltokenvalue';

ProviderContainer _container(
  FakeHomeWidgetBridge bridge, {
  FakeWidgetConfigRepository? configs,
  Locale? locale,
  bool withSettings = true,
}) {
  final container = ProviderContainer(
    overrides: [
      ...widgetOverrides(
        bridge: bridge,
        configs: configs ?? FakeWidgetConfigRepository(),
        locale: locale,
        withSettings: withSettings,
      ),
    ],
  );
  addTearDown(container.dispose);
  container.listen(widgetSyncProvider, (_, _) {});
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('widgetSyncProvider', () {
    test('publishes a snapshot for every dashboard role', () async {
      final bridge = FakeHomeWidgetBridge();
      final container = _container(bridge);

      await pumpEventQueue();

      final snapshot = container.read(widgetSyncProvider).value;
      expect(snapshot, isNotNull);
      expect(bridge.published.last, snapshot);
      expect(snapshot!.roles.map((r) => r.roleId), [1, 2, 3]);
      expect(snapshot.generatedAt, widgetNow.toUtc());
    });

    test('counts only enabled check-in games that have roles', () async {
      final bridge = FakeHomeWidgetBridge();
      _container(bridge);

      await pumpEventQueue();

      expect(bridge.published.last.checkIn.total, 1);
    });

    test('localizes labels with the app language', () async {
      final english = FakeHomeWidgetBridge();
      final indonesian = FakeHomeWidgetBridge();
      _container(english, locale: const Locale('en'));
      _container(indonesian, locale: const Locale('id'));

      await pumpEventQueue();

      expect(english.published.last.labels['app'], 'HoYo AIO');
      expect(english.published.last.labels['short.resin'], 'Resin');
      expect(
        indonesian.published.last.labels.keys,
        english.published.last.labels.keys,
      );
    });

    test(
      'returns null and publishes nothing before check-in settings load',
      () async {
        final bridge = FakeHomeWidgetBridge();
        final container = _container(bridge, withSettings: false);

        await pumpEventQueue();

        expect(container.read(widgetSyncProvider).value, isNull);
        expect(bridge.published, isEmpty);
      },
    );

    test('republishes with the new config after a widget save', () async {
      final bridge = FakeHomeWidgetBridge();
      final configs = FakeWidgetConfigRepository();
      final container = _container(bridge, configs: configs);
      await pumpEventQueue();
      final before = bridge.published.length;

      await container
          .read(widgetConfigRepositoryProvider)
          .save(config(theme: 'dark'), accountId: testAccountId);
      await pumpEventQueue();

      expect(bridge.published.length, greaterThan(before));
      expect(bridge.published.last.widgets, [config(theme: 'dark')]);
    });

    test('republishes after a save to the real widget_configs table', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final bridge = FakeHomeWidgetBridge();
      final container = ProviderContainer(
        overrides: [
          ...widgetOverrides(bridge: bridge),
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);
      container.listen(widgetSyncProvider, (_, _) {});
      await pumpEventQueue();

      await container
          .read(widgetConfigRepositoryProvider)
          .save(config(roleId: null, accent: 'lime'), accountId: null);
      await pumpEventQueue(times: 50);

      expect(bridge.published.last.widgets.single.accent, 'lime');
    });

    test('never includes the account cookie stored in the vault', () async {
      FlutterSecureStorage.setMockInitialValues({});
      await CookieVault().save(
        testAccountId,
        HoyolabCookie.parse(
          'ltuid_v2=$testAccountId; ltoken_v2=$_fakeLtoken; '
          'cookie_token_v2=v2_fakecookietoken',
        ),
      );
      expect(await CookieVault().cookieHeader(testAccountId), isNotNull);
      final bridge = FakeHomeWidgetBridge();
      _container(bridge);

      await pumpEventQueue();

      final encoded = jsonEncode(bridge.published.last.toJson());
      expect(encoded, isNot(contains(_fakeLtoken)));
      expect(encoded, isNot(contains('v2_fakecookietoken')));
      expect(encoded, isNot(contains('ltoken')));
      expect(encoded, isNot(contains(testAccountId)));
    });
  });

  group('placed and pin providers', () {
    test('read placed widgets and pin support from the bridge', () async {
      final bridge = FakeHomeWidgetBridge(
        placedWidgets: const [
          PlacedWidget(widgetId: 4, size: HomeWidgetSize.large),
        ],
        pinSupported: false,
      );
      final container = _container(bridge);

      final placed = await container.read(placedWidgetsProvider.future);
      final canPin = await container.read(canPinWidgetProvider.future);

      expect(placed.single.widgetId, 4);
      expect(canPin, isFalse);
    });

    test(
      'updateHomeWidgetsProvider builds from the overridden sources',
      () async {
        final bridge = FakeHomeWidgetBridge();
        final container = _container(bridge);

        final WidgetSnapshot snapshot = await container
            .read(updateHomeWidgetsProvider)
            .call(roles: [zzzRole], checkInGames: const {}, labels: const {});

        expect(snapshot.roles.single.roleId, zzzRole.id);
      },
    );
  });
}
