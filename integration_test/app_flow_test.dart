import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/app.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/app/flavor_provider.dart';
import 'package:hoyo_aio/app/provider_retry.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/design_system/components/stamina_ring_card.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio_provider.dart';
import 'package:hoyo_aio/core/storage/cookie_vault.dart';
import 'package:hoyo_aio/features/background/presentation/providers/background_sync_provider.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/providers/widget_sync_provider.dart';
import 'package:hoyo_aio/features/notifications/data/notification_service.dart';
import 'package:hoyo_aio/features/notifications/presentation/providers/notification_sync_provider.dart';
import 'package:hoyo_aio/features/tracker/data/authkey_vault.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test/core/storage/_support/memory_secure_storage.dart';
import '../test/features/checkin/_support/check_in_fixtures.dart';
import '../test/helpers/app_overrides.dart' show FakeNotificationService;
import 'fixtures.dart';

const _cookie =
    'ltuid_v2=800000001; ltoken_v2=v2_fake_token; ltmid_v2=fake_mid; '
    'cookie_token_v2=v2_fake_cookie; account_id_v2=800000001; '
    'account_mid_v2=fake_mid';

class FakeHoyolab implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final signed = <Game>{};

  Map<String, Object?> _reply(RequestOptions options) {
    final path = options.uri.path;
    if (path == HoyolabConfig.recordCardPath) {
      return jsonDecode(recordCardJson) as Map<String, Object?>;
    }
    final notes = {
      HoyolabConfig.genshinNotePath: notesGenshinJson,
      HoyolabConfig.starRailNotePath: notesStarRailJson,
      HoyolabConfig.zzzNotePath: notesZzzJson,
    }[path];
    if (notes != null) return jsonDecode(notes) as Map<String, Object?>;
    for (final MapEntry(key: game, value: endpoint)
        in HoyolabConfig.checkIn.entries) {
      if (options.uri.host != endpoint.host ||
          !path.startsWith(endpoint.basePath)) {
        continue;
      }
      final action = path.substring(endpoint.basePath.length);
      return switch (action) {
        '/info' => ok(infoJson(isSign: signed.contains(game))),
        '/home' => ok(homeJson(game)),
        '/award' => ok(awardJson(const [])),
        '/sign' => () {
          signed.add(game);
          return ok(signJson());
        }(),
        _ => ok(const <String, Object?>{}),
      };
    }
    return ok(const <String, Object?>{'list': <Object?>[]});
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(_reply(options)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> tapWhenReady(WidgetTester tester, Finder finder) async {
  await pumpUntil(tester, finder);
  await tester.ensureVisible(finder.first);
  await tester.pump();
  await tester.tap(finder.first);
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final l10n = lookupAppLocalizations(const Locale('en'));

  testWidgets(
    'onboarding, paste cookie, dashboard and check-in against a fake HoYoLAB',
    (tester) async {
      final server = FakeHoyolab();
      final storage = MemorySecureStorage();
      final container = ProviderContainer(
        retry: noProviderRetry,
        overrides: [
          flavorProvider.overrideWithValue(Flavor.prod),
          appDatabaseProvider.overrideWith((ref) {
            final db = AppDatabase(NativeDatabase.memory());
            ref.onDispose(db.close);
            return db;
          }),
          cookieVaultProvider.overrideWithValue(CookieVault(storage)),
          authkeyVaultProvider.overrideWithValue(AuthkeyVault(storage)),
          notificationServiceProvider.overrideWithValue(
            FakeNotificationService(),
          ),
          notificationSyncProvider.overrideWith((_) async => 0),
          backgroundSyncProvider.overrideWith((_) async {}),
          widgetSyncProvider.overrideWith((_) async => null),
        ],
      );
      addTearDown(container.dispose);
      container.read(hoyolabDioProvider).httpClientAdapter = server;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const App(flavor: Flavor.prod),
        ),
      );

      await tapWhenReady(tester, find.text(l10n.onboardingSkip));
      await tapWhenReady(tester, find.text(l10n.addAccountPasteTitle));
      await tapWhenReady(tester, find.text(l10n.addAccountContinue));

      await pumpUntil(tester, find.byType(TextField));
      await tester.enterText(find.byType(TextField).first, _cookie);
      await tapWhenReady(tester, find.text(l10n.pasteCookieVerify));

      await tapWhenReady(
        tester,
        find.textContaining(RegExp(r'^Add \d+ Roles?$')),
      );

      await pumpUntil(tester, find.byType(StaminaRingCard));
      expect(
        server.requests.map((r) => r.uri.path),
        contains(HoyolabConfig.genshinNotePath),
      );
      expect(server.requests.every((r) => r.uri.scheme == 'https'), isTrue);

      await tapWhenReady(tester, find.text(l10n.navCheckIn));
      await tapWhenReady(tester, find.text(l10n.checkInNow));
      await pumpUntil(tester, find.textContaining('claimed'));
      expect(server.signed, contains(Game.genshin));
    },
  );
}
