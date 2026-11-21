import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio_provider.dart';
import 'package:hoyo_aio/features/codes/data/codes_repository_impl.dart';
import 'package:hoyo_aio/features/codes/domain/redeem_code.dart';

import '../../tracker/_support/tracker_support.dart';

Map<String, Object?> bonus(
  String code, {
  String status = 'ON',
  Object? offlineAt,
  List<int> rewards = const [60, 5],
}) => {
  'exchange_code': code,
  'code_status': status,
  'offline_at': ?offlineAt,
  'icon_bonuses': [
    for (final amount in rewards) {'bonus_num': amount, 'icon_url': 'x'},
    {'icon_url': 'no amount'},
  ],
};

void main() {
  late AppDatabase db;
  late Map<Game, List<Map<String, Object?>>> listing;
  late DateTime now;
  late CodesRepositoryImpl repository;
  final gameById = {
    for (final MapEntry(:key, :value) in HoyolabConfig.communityGameIds.entries)
      '$value': key,
  };

  Object? handle(RequestOptions options) {
    final game = gameById[options.uri.queryParameters['game_id']];
    return {
      'retcode': 0,
      'data': {
        'modules': [
          {'module_type': 1, 'exchange_group': null},
          {
            'module_type': HoyolabConfig.codesModuleType,
            'exchange_group': {'bonuses': listing[game] ?? const []},
          },
        ],
      },
    };
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    listing = {};
    now = testNow;
    repository = CodesRepositoryImpl(fakeDio(handle), db, now: () => now);
  });

  test('first run stores codes silently as read', () async {
    listing[Game.genshin] = [bonus('GENSHINGIFT')];

    final added = await repository.refresh();

    expect(added, isEmpty);
    final stored = await repository.watch().first;
    expect(stored.single.code, 'GENSHINGIFT');
    expect(stored.single.unread, isFalse);
  });

  test('a new code later produces exactly one new item', () async {
    listing[Game.genshin] = [bonus('OLDCODE')];
    await repository.refresh();
    now = testNow.add(const Duration(hours: 1));
    listing[Game.starRail] = [
      bonus('NEWCODE', rewards: [50]),
    ];

    final added = await repository.refresh();
    final again = await repository.refresh();

    expect(added.map((code) => code.code), ['NEWCODE']);
    expect(added.single.game, Game.starRail);
    expect(added.single.unread, isTrue);
    expect(again, isEmpty);
    final stored = await repository.watch().first;
    expect(stored.map((code) => code.code), ['NEWCODE', 'OLDCODE']);
  });

  test('maps rewards, expiry and skips inactive or empty codes', () async {
    final offline = DateTime(2026, 11, 23, 4);
    listing[Game.zzz] = [
      bonus('ZZZCODE', offlineAt: offline.millisecondsSinceEpoch ~/ 1000),
      bonus('ZEROEXPIRY', offlineAt: 0, rewards: []),
      bonus('OFFCODE', status: 'OFF'),
      bonus(''),
      {'exchange_code': 'NOSTATUS'},
    ];

    await repository.refresh();

    final stored = {
      for (final code in await repository.watch().first) code.code: code,
    };
    expect(stored.keys, unorderedEquals(['ZZZCODE', 'ZEROEXPIRY']));
    expect(stored['ZZZCODE']?.rewards, [60, 5]);
    expect(stored['ZZZCODE']?.expiresAt, offline);
    expect(stored['ZEROEXPIRY']?.expiresAt, isNull);
    expect(stored['ZEROEXPIRY']?.rewards, isEmpty);
  });

  test('a code that disappears becomes inactive and expired', () async {
    listing[Game.genshin] = [bonus('GONE'), bonus('STAYS')];
    await repository.refresh();
    listing[Game.genshin] = [bonus('STAYS')];

    await repository.refresh();

    final stored = {
      for (final code in await repository.watch().first) code.code: code,
    };
    expect(stored['GONE']?.active, isFalse);
    expect(stored['GONE']?.isExpiredAt(now), isTrue);
    expect(stored['STAYS']?.active, isTrue);
  });

  test('a code that comes back is active again', () async {
    listing[Game.genshin] = [bonus('BACK')];
    await repository.refresh();
    listing[Game.genshin] = [];
    await repository.refresh();
    listing[Game.genshin] = [bonus('BACK')];

    final added = await repository.refresh();

    expect(added, isEmpty);
    expect((await repository.watch().first).single.active, isTrue);
  });

  test('markAllRead and markRedeemed update rows', () async {
    listing[Game.genshin] = [bonus('A')];
    await repository.refresh();
    listing[Game.genshin] = [bonus('A'), bonus('B')];
    await repository.refresh();
    expect(
      (await repository.watch().first).where((c) => c.unread),
      hasLength(1),
    );

    await repository.markAllRead();
    await repository.markRedeemed(Game.genshin, 'B');

    final stored = await repository.watch().first;
    expect(stored.where((code) => code.unread), isEmpty);
    expect(stored.firstWhere((code) => code.code == 'B').redeemedAt, now);
    expect(stored.firstWhere((code) => code.code == 'A').redeemedAt, isNull);
  });

  test('broken stored rewards decode as empty', () async {
    await db
        .into(db.seenCodes)
        .insert(
          SeenCodesCompanion.insert(
            game: Game.genshin,
            code: 'BROKEN',
            rewards: const Value('not json'),
            firstSeenAt: testNow,
          ),
        );
    await db
        .into(db.seenCodes)
        .insert(
          SeenCodesCompanion.insert(
            game: Game.genshin,
            code: 'OBJECT',
            rewards: const Value('{"a":1}'),
            firstSeenAt: testNow,
          ),
        );

    final stored = await repository.watch().first;

    expect(stored.map((code) => code.rewards), [isEmpty, isEmpty]);
  });

  test('redeemUri appends the code to the official page', () {
    expect(
      redeemUri(Game.genshin, 'ABC').toString(),
      '${HoyolabConfig.redeemUrls[Game.genshin]}ABC',
    );
  });

  group('providers', () {
    RedeemCode code(String value, {bool unread = true, bool active = true}) =>
        RedeemCode(
          game: Game.genshin,
          code: value,
          rewards: const [],
          active: active,
          firstSeenAt: testNow,
          unread: unread,
        );

    test('unreadCodes counts unread codes that are not expired', () async {
      final container = ProviderContainer(
        overrides: [
          redeemCodesProvider.overrideWith(
            (ref) => Stream.value([
              code('A'),
              code('B', unread: false),
              code('C', active: false),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(unreadCodesProvider, (_, _) {});

      await container.read(redeemCodesProvider.future);

      expect(container.read(unreadCodesProvider), 1);
    });

    test('repository and stream providers read the database', () async {
      final container = ProviderContainer(
        overrides: [
          hoyolabDioProvider.overrideWithValue(Dio()),
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(codesRepositoryProvider),
        isA<CodesRepositoryImpl>(),
      );
      container.listen(redeemCodesProvider, (_, _) {});
      expect(await container.read(redeemCodesProvider.future), isEmpty);
    });
  });
}
