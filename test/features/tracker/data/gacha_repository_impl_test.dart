import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio_provider.dart';
import 'package:hoyo_aio/features/tracker/data/authkey_vault.dart';
import 'package:hoyo_aio/features/tracker/data/gacha_repository_impl.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_repository.dart';

import '../_support/tracker_support.dart';

class GachaServer {
  final banners = <String, List<int>>{};
  final requests = <Map<String, String>>[];
  AppException? error;

  Object? handle(RequestOptions options) {
    final query = options.uri.queryParameters;
    requests.add(query);
    if (error case final failure?) throw failure;
    final banner = query['gacha_type'] ?? query['real_gacha_type'] ?? '';
    final endId = int.parse(query['end_id'] ?? '0');
    final ids = [
      for (final id in banners[banner] ?? const <int>[])
        if (endId == 0 || id < endId) id,
    ].take(HoyolabConfig.gachaPageSize);
    return {
      'retcode': 0,
      'data': {
        'list': [
          for (final id in ids)
            {
              'id': '$id',
              'uid': '800000001',
              'gacha_type': banner,
              'name': id % 10 == 0 ? 'Five $id' : 'Item $id',
              'item_type': 'Character',
              'rank_type': id % 10 == 0 ? '5' : '3',
              'time': '2026-11-20 10:00:00',
            },
          {'id': 'not-a-number', 'uid': '1', 'name': 'x', 'rank_type': '3'},
        ],
      },
    };
  }

  List<int> descending(int from, int to) => [
    for (var id = to; id >= from; id--) id,
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AuthkeyVault vault;
  late GachaServer server;
  late GachaRepository repository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    vault = AuthkeyVault(const FlutterSecureStorage());
    server = GachaServer();
    repository = GachaRepositoryImpl(
      fakeDio(server.handle),
      db,
      vault,
      now: () => testNow,
    );
  });

  test('sync without a stored link throws AuthkeyExpiredException', () async {
    expect(
      () => repository.sync(Game.genshin),
      throwsA(isA<AuthkeyExpiredException>()),
    );
  });

  test('importLink rejects a bad link with ParseException', () async {
    expect(
      () => repository.importLink('https://example.com/?authkey=x'),
      throwsA(isA<ParseException>()),
    );
  });

  test('importLink stores the link and reports its expiry', () async {
    final game = await repository.importLink(genshinLink());

    expect(game, Game.genshin);
    expect(
      await repository.linkExpiresAt(Game.genshin),
      testNow.add(const Duration(hours: 24)).toUtc(),
    );
  });

  group('sync', () {
    setUp(() async {
      await repository.importLink(genshinLink());
      server.banners['301'] = server.descending(101, 145);
      server.banners['200'] = server.descending(1, 3);
    });

    test('fetches every banner page by page and stores newest first', () async {
      final progress = <int>[];

      final fetched = await repository.sync(
        Game.genshin,
        onProgress: progress.add,
      );

      final banners = server.requests.map((query) => query['gacha_type']);
      expect(
        banners.toSet(),
        HoyolabConfig.gachaBanners[Game.genshin]!.toSet(),
      );
      final pages301 = server.requests.where((q) => q['gacha_type'] == '301');
      expect(pages301.map((q) => q['end_id']), ['0', '126', '106']);
      expect(pages301.map((q) => q['page']), ['1', '2', '3']);
      expect(fetched, 48);
      expect(progress.last, fetched);
      final records = await repository.watch(Game.genshin).first;
      expect(records, hasLength(48));
      expect(records.first.id, 145);
      expect(
        records.map((record) => record.id),
        orderedEquals(
          [...records.map((record) => record.id)]..sort((a, b) => b - a),
        ),
      );
      expect(records.firstWhere((r) => r.id == 140).rank, 5);
      expect(records.firstWhere((r) => r.id == 2).banner, '200');
    });

    test(
      'sends only the stored params plus paging to the gacha host',
      () async {
        await repository.sync(Game.genshin);

        final query = server.requests.first;
        expect(query['authkey'], fakeAuthkey);
        expect(query['lang'], 'en');
        expect(query['size'], '${HoyolabConfig.gachaPageSize}');
        expect(query.containsKey('init_type'), isFalse);
        expect(query.containsKey('timestamp'), isFalse);
      },
    );

    test(
      'second sync stops at the last stored id and adds no duplicates',
      () async {
        await repository.sync(Game.genshin);
        server.requests.clear();
        server.banners['301'] = server.descending(101, 147);

        final fetched = await repository.sync(Game.genshin);

        final pages301 = server.requests.where((q) => q['gacha_type'] == '301');
        expect(pages301, hasLength(1));
        expect(fetched, 3 + 20);
        final records = await repository.watch(Game.genshin).first;
        expect(records, hasLength(50));
        expect(records.map((r) => r.id).toSet(), hasLength(50));
      },
    );

    test('never writes the authkey into gacha rows', () async {
      await repository.sync(Game.genshin);

      final rows = await db.select(db.gachaRecords).get();
      expect(rows, isNotEmpty);
      expect(
        rows.map((row) => row.toString()).join(),
        isNot(contains(fakeAuthkey)),
      );
    });

    for (final retcode in HoyolabConfig.gachaExpiredRetcodes) {
      test(
        'server retcode $retcode drops the link and throws expired',
        () async {
          server.error = ServerException(retcode: retcode);

          await expectLater(
            repository.sync(Game.genshin),
            throwsA(isA<AuthkeyExpiredException>()),
          );
          expect(await repository.linkExpiresAt(Game.genshin), isNull);
        },
      );

      test(
        'cookie retcode $retcode drops the link and throws expired',
        () async {
          server.error = CookieExpiredException(retcode: retcode);

          await expectLater(
            repository.sync(Game.genshin),
            throwsA(isA<AuthkeyExpiredException>()),
          );
        },
      );
    }

    test('other server errors are rethrown and keep the link', () async {
      server.error = const ServerException(retcode: -1);

      await expectLater(
        repository.sync(Game.genshin),
        throwsA(isA<ServerException>()),
      );
      expect(await repository.linkExpiresAt(Game.genshin), isNotNull);
    });

    test('other cookie errors are rethrown', () async {
      server.error = const CookieExpiredException(retcode: 10001);

      await expectLater(
        repository.sync(Game.genshin),
        throwsA(isA<CookieExpiredException>()),
      );
    });
  });

  test('ZZZ uses real_gacha_type and its game_biz', () async {
    await repository.importLink(
      'https://public-operation-nap-sg.hoyoverse.com/common/gacha_record/api/'
      'getGachaLog?authkey=$fakeAuthkey&game_biz=nap_global',
    );

    await repository.sync(Game.zzz);

    expect(server.requests.first['real_gacha_type'], '2');
    expect(server.requests.first['game_biz'], 'nap_global');
  });

  test('provider wires dio, database and vault', () {
    final container = ProviderContainer(
      overrides: [
        hoyolabDioProvider.overrideWithValue(Dio()),
        appDatabaseProvider.overrideWithValue(db),
        authkeyVaultProvider.overrideWithValue(vault),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(gachaRepositoryProvider), isA<GachaRepositoryImpl>());
  });
}
