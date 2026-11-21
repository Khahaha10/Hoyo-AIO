import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/game_region.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio_provider.dart';
import 'package:hoyo_aio/core/storage/cookie_vault.dart';
import 'package:hoyo_aio/core/storage/hoyolab_cookie.dart';
import 'package:hoyo_aio/features/accounts/data/account_repository_impl.dart';
import 'package:hoyo_aio/features/accounts/domain/detected_role.dart';

import '../_support/account_fakes.dart';

Map<String, dynamic> _fixture() =>
    jsonDecode(File('test/fixtures/record_card.json').readAsStringSync())
        as Map<String, dynamic>;

class _OrderedVault extends FakeCookieVault {
  _OrderedVault(this.db);

  final AppDatabase db;
  int? accountRowsAtSave;

  @override
  Future<void> save(String accountId, HoyolabCookie cookie) async {
    accountRowsAtSave = (await db.select(db.accounts).get()).length;
    await super.save(accountId, cookie);
  }
}

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late AppDatabase db;
  late FakeCookieVault vault;
  late FakeHttpAdapter adapter;
  late AccountRepositoryImpl repository;
  final cookie = HoyolabCookie.parse(fakeCookieText);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    vault = FakeCookieVault();
    adapter = FakeHttpAdapter(_fixture());
    repository = AccountRepositoryImpl(
      Dio()..httpClientAdapter = adapter,
      db,
      vault,
    );
  });

  Future<void> addWidget(int widgetId, String accountId) => db
      .into(db.widgetConfigs)
      .insert(
        WidgetConfigsCompanion.insert(
          widgetId: Value(widgetId),
          size: WidgetSize.medium,
          accountId: Value(accountId),
          theme: WidgetTheme.light,
          fontSize: WidgetFontSize.medium,
          updatedAt: DateTime.utc(2026),
        ),
      );

  group('detectRoles', () {
    test(
      'maps record cards of all four games and skips unusable cards',
      () async {
        final roles = await repository.detectRoles(
          accountId: 'pending:$fakeUid',
          hoyolabUid: fakeUid,
        );

        expect(roles.map((r) => r.game), [
          Game.genshin,
          Game.starRail,
          Game.zzz,
          Game.hi3,
        ]);
        expect(roles[0].uid, '800000001');
        expect(roles[0].region, GameRegion.asia);
        expect(roles[0].regionName, 'Asia Server');
        expect(roles[0].level, 60);
        expect(roles[1].region, GameRegion.america);
        expect(roles[2].region, GameRegion.europe);
        expect(roles[2].nickname, 'Proxy');
        expect(roles[3].region, isNull);
        expect(roles[3].server, 'overseas01');
      },
    );

    test('sends the HoYoLAB uid as query parameter', () async {
      await repository.detectRoles(accountId: 'a', hoyolabUid: fakeUid);

      expect(adapter.requests.single.uri.queryParameters['uid'], fakeUid);
      expect(adapter.requests.single.uri.scheme, 'https');
    });

    test('returns no roles when the body has no list', () async {
      adapter.body = {'retcode': 0, 'data': null};

      final roles = await repository.detectRoles(
        accountId: 'a',
        hoyolabUid: fakeUid,
      );

      expect(roles, isEmpty);
    });

    test('throws ParseException when a card has a wrong field type', () async {
      adapter.body = {
        'data': {
          'list': [
            {'game_id': 'two'},
          ],
        },
      };

      await expectLater(
        repository.detectRoles(accountId: 'a', hoyolabUid: fakeUid),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('saveAccount', () {
    final gi = detectedRole(Game.genshin);
    final hsr = detectedRole(Game.starRail, uid: '800000002');

    test('throws NoRolesException without roles and stores nothing', () async {
      await expectLater(
        repository.saveAccount(
          accountId: fakeUid,
          cookie: cookie,
          roles: const [],
          selected: const {},
        ),
        throwsA(isA<NoRolesException>()),
      );
      expect(vault.stored, isEmpty);
      expect(await db.select(db.accounts).get(), isEmpty);
    });

    test('writes the vault before any database row', () async {
      final ordered = _OrderedVault(db);
      final repo = AccountRepositoryImpl(Dio(), db, ordered);

      await repo.saveAccount(
        accountId: fakeUid,
        cookie: cookie,
        roles: [gi],
        selected: {gi},
      );

      expect(ordered.accountRowsAtSave, 0);
      expect(ordered.stored[fakeUid], cookie);
      expect(await db.select(db.accounts).get(), hasLength(1));
    });

    test(
      'stores nothing in the database when the vault rejects the cookie',
      () async {
        await expectLater(
          repository.saveAccount(
            accountId: fakeUid,
            cookie: HoyolabCookie.parse('ltuid_v2=1'),
            roles: [gi],
            selected: {gi},
          ),
          throwsA(isA<CookieExpiredException>()),
        );
        expect(await db.select(db.accounts).get(), isEmpty);
        expect(await db.select(db.gameRoles).get(), isEmpty);
      },
    );

    test(
      'saves the account with roles and enabled flags from the selection',
      () async {
        await repository.saveAccount(
          accountId: fakeUid,
          cookie: cookie,
          roles: [gi, hsr],
          selected: {hsr},
        );

        final account = await db.select(db.accounts).getSingle();
        final roles = await db.select(db.gameRoles).get();
        expect(account.id, fakeUid);
        expect(account.nickname, hsr.nickname);
        expect(account.status, AccountStatus.valid);
        expect(
          {for (final r in roles) r.game: r.enabled},
          {Game.genshin: false, Game.starRail: true},
        );
      },
    );

    test('updates instead of duplicating for the same HoYoLAB id', () async {
      await repository.saveAccount(
        accountId: fakeUid,
        cookie: cookie,
        roles: [gi, hsr],
        selected: {gi, hsr},
      );
      await db.markAccountExpired(fakeUid);
      final renamed = gi.copyWith(nickname: 'Renamed', level: 61);

      await repository.saveAccount(
        accountId: fakeUid,
        cookie: cookie,
        roles: [renamed, hsr],
        selected: {renamed},
      );

      final accounts = await db.select(db.accounts).get();
      final roles = await db.select(db.gameRoles).get();
      expect(accounts, hasLength(1));
      expect(accounts.single.nickname, 'Renamed');
      expect(accounts.single.status, AccountStatus.valid);
      expect(roles, hasLength(2));
      final giRow = roles.firstWhere((r) => r.game == Game.genshin);
      expect(giRow.level, 61);
      expect(roles.firstWhere((r) => r.game == Game.starRail).enabled, false);
    });
  });

  group('watchAccounts', () {
    test(
      'groups roles under their account and keeps accounts without roles',
      () async {
        await repository.saveAccount(
          accountId: fakeUid,
          cookie: cookie,
          roles: [detectedRole(Game.genshin), detectedRole(Game.zzz)],
          selected: {detectedRole(Game.genshin)},
        );
        await db
            .into(db.accounts)
            .insert(
              AccountsCompanion.insert(
                id: '800000009',
                nickname: 'Empty',
                status: AccountStatus.needsLogin,
                createdAt: DateTime.utc(2030),
                updatedAt: DateTime.utc(2030),
              ),
            );

        final accounts = await repository.watchAccounts().first;

        expect(accounts.map((a) => a.id), [fakeUid, '800000009']);
        expect(accounts.first.roles, hasLength(2));
        expect(accounts.first.enabledRoles.single.game, Game.genshin);
        expect(accounts.last.roles, isEmpty);
        expect(accounts.last.needsAttention, isTrue);
      },
    );
  });

  group('deleteAccount', () {
    test('removes vault entry, account, roles and widget configs', () async {
      await repository.saveAccount(
        accountId: fakeUid,
        cookie: cookie,
        roles: [detectedRole(Game.genshin)],
        selected: {detectedRole(Game.genshin)},
      );
      await addWidget(1, fakeUid);
      await addWidget(2, fakeUid);
      expect(await repository.countWidgets(fakeUid), 2);

      await repository.deleteAccount(fakeUid);

      expect(vault.stored, isEmpty);
      expect(vault.log.last, 'delete:$fakeUid');
      expect(await db.select(db.accounts).get(), isEmpty);
      expect(await db.select(db.gameRoles).get(), isEmpty);
      expect(await db.select(db.widgetConfigs).get(), isEmpty);
      expect(await repository.countWidgets(fakeUid), 0);
    });

    test('keeps other accounts untouched', () async {
      final other = detectedRole(Game.zzz, uid: '800000002');
      await repository.saveAccount(
        accountId: fakeUid,
        cookie: cookie,
        roles: [detectedRole(Game.genshin)],
        selected: {detectedRole(Game.genshin)},
      );
      await repository.saveAccount(
        accountId: '800000002',
        cookie: cookie,
        roles: [other],
        selected: {other},
      );
      await addWidget(3, '800000002');

      await repository.deleteAccount(fakeUid);

      expect((await db.select(db.accounts).getSingle()).id, '800000002');
      expect(await db.select(db.gameRoles).get(), hasLength(1));
      expect(await repository.countWidgets('800000002'), 1);
      expect(vault.stored.keys, ['800000002']);
    });
  });

  group('account status', () {
    test('valid becomes expired and needsLogin stays needsLogin', () async {
      await repository.saveAccount(
        accountId: fakeUid,
        cookie: cookie,
        roles: [detectedRole(Game.genshin)],
        selected: {detectedRole(Game.genshin)},
      );
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: '800000009',
              nickname: 'Imported',
              status: AccountStatus.needsLogin,
              createdAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026),
            ),
          );

      await db.markAccountExpired(fakeUid);
      await db.markAccountExpired('800000009');

      final statuses = {
        for (final a in await db.select(db.accounts).get()) a.id: a.status,
      };
      expect(statuses, {
        fakeUid: AccountStatus.expired,
        '800000009': AccountStatus.needsLogin,
      });
    });

    test(
      'expired status survives closing and reopening the database',
      () async {
        final dir = await Directory.systemTemp.createTemp('hoyo_accounts');
        addTearDown(() => dir.delete(recursive: true));
        final file = File('${dir.path}/db.sqlite');
        final first = AppDatabase(NativeDatabase(file));
        await AccountRepositoryImpl(Dio(), first, vault).saveAccount(
          accountId: fakeUid,
          cookie: cookie,
          roles: [detectedRole(Game.genshin)],
          selected: {detectedRole(Game.genshin)},
        );
        await first.markAccountExpired(fakeUid);
        await first.close();

        final reopened = AppDatabase(NativeDatabase(file));
        addTearDown(reopened.close);
        final accounts = await AccountRepositoryImpl(
          Dio(),
          reopened,
          vault,
        ).watchAccounts().first;

        expect(accounts.single.status, AccountStatus.expired);
        expect(accounts.single.needsAttention, isTrue);
      },
    );
  });

  test('provider wires dio, database and vault', () {
    final container = ProviderContainer(
      overrides: [
        hoyolabDioProvider.overrideWithValue(Dio()),
        appDatabaseProvider.overrideWithValue(db),
        cookieVaultProvider.overrideWithValue(vault),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(accountRepositoryProvider),
      isA<AccountRepositoryImpl>(),
    );
  });

  test('DetectedRole equality drives selection sets', () {
    expect(<DetectedRole>{
      detectedRole(Game.genshin),
      detectedRole(Game.genshin),
    }, hasLength(1));
  });
}
