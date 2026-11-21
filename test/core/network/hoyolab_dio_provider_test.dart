import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/app/flavor_provider.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/logging/app_logger.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio_provider.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';
import 'package:hoyo_aio/core/storage/cookie_vault.dart';
import 'package:hoyo_aio/core/storage/hoyolab_cookie.dart';
import 'package:hoyo_aio/core/storage/pending_cookies.dart';

import '../storage/_support/memory_secure_storage.dart';
import '_support/fake_adapter.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late CookieVault vault;
  late ProviderContainer container;
  late FakeAdapter adapter;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    vault = CookieVault(MemorySecureStorage());
    container = ProviderContainer(
      overrides: [
        flavorProvider.overrideWithValue(Flavor.prod),
        appDatabaseProvider.overrideWithValue(db),
        cookieVaultProvider.overrideWithValue(vault),
      ],
    );
    adapter = FakeAdapter.json({'retcode': -100});
    container.read(hoyolabDioProvider).httpClientAdapter = adapter;
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    final when = DateTime.utc(2026, 11, 21);
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: '800000001',
            nickname: 'Traveler',
            status: AccountStatus.valid,
            createdAt: when,
            updatedAt: when,
          ),
        );
  });

  Future<void> request(String accountId) async {
    await expectLater(
      container
          .read(hoyolabDioProvider)
          .getUri<Object?>(
            Uri.https(HoyolabConfig.gameRecordHost, '/$accountId'),
            options: hoyolabOptions(
              accountId: accountId,
              profile: HeaderProfile.gameRecord,
            ),
          ),
      throwsA(
        isA<DioException>().having(
          (e) => e.error,
          'error',
          isA<CookieExpiredException>(),
        ),
      ),
    );
  }

  test('reads the vault cookie and marks the account expired', () async {
    await vault.save(
      '800000001',
      HoyolabCookie.parse('ltuid_v2=800000001; ltoken_v2=fake'),
    );

    await request('800000001');
    await pumpEventQueue();

    final account = await db.select(db.accounts).getSingle();
    expect(adapter.requests.single.headers['Cookie'], contains('fake'));
    expect(account.status, AccountStatus.expired);
  });

  test('uses a pending cookie and never marks a pending account', () async {
    final id = PendingCookies.idFor('800000002');
    container
        .read(pendingCookiesProvider)
        .put(id, 'ltuid_v2=800000002; ltoken_v2=pending');

    await request(id);
    await pumpEventQueue();

    final account = await db.select(db.accounts).getSingle();
    expect(adapter.requests.single.headers['Cookie'], contains('pending'));
    expect(account.status, AccountStatus.valid);
  });

  test('appLoggerProvider follows the flavor', () {
    expect(container.read(appLoggerProvider), isA<AppLogger>());
  });

  test('flavorProvider must be overridden', () {
    final bare = ProviderContainer();
    addTearDown(bare.dispose);

    expect(() => bare.read(flavorProvider), throwsA(anything));
  });
}
