import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/tracker/data/gacha_repository_impl.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_record.dart';
import 'package:hoyo_aio/features/tracker/presentation/providers/tracker_providers.dart';

import '../../_support/tracker_support.dart';

void main() {
  late FakeGachaRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeGachaRepository(
      records: {
        Game.genshin: [
          gachaRecord(3, rank: 5, name: 'Limited'),
          gachaRecord(2, rank: 5, name: 'Diluc'),
          gachaRecord(1),
          gachaRecord(4, rank: 5, name: 'Diluc', banner: '200'),
        ],
      },
      expiry: testNow.add(const Duration(hours: 3)),
    );
    container = ProviderContainer(
      overrides: [
        gachaRepositoryProvider.overrideWithValue(repository),
        ...clockOverrides(),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<BannerPity> pityOf(String banner) async {
    container.listen(bannerPityProvider(Game.genshin, banner), (_, _) {});
    await container.read(gachaRecordsProvider(Game.genshin).future);
    return container.read(bannerPityProvider(Game.genshin, banner));
  }

  test('limited banner uses the standard pool for 50/50', () async {
    final pity = await pityOf('301');

    expect(pity.total, 3);
    expect(pity.fiveStars.map((pull) => pull.fiftyFifty), [
      FiftyFifty.guaranteed,
      FiftyFifty.lost,
    ]);
  });

  test('standard banner has no 50/50', () async {
    final pity = await pityOf('200');

    expect(pity.total, 1);
    expect(pity.fiveStars.single.fiftyFifty, isNull);
  });

  test('link expiry comes from the repository', () async {
    expect(
      await container.read(gachaLinkExpiryProvider(Game.genshin).future),
      repository.expiry,
    );
  });

  test('sync tracks progress and records the last sync time', () async {
    final states = <GachaSyncState>[];
    container.listen(gachaSyncProvider, (_, next) => states.add(next));

    await container.read(gachaSyncProvider.notifier).sync(Game.zzz);

    expect(states.first.syncing, Game.zzz);
    expect(states.map((state) => state.fetched), contains(7));
    final last = container.read(gachaSyncProvider);
    expect(last.syncing, isNull);
    expect(last.lastSynced[Game.zzz], testNow);
  });

  test('a second sync while one runs is ignored', () async {
    repository.syncGate = Completer<void>();
    final notifier = container.read(gachaSyncProvider.notifier);

    final first = notifier.sync(Game.genshin);
    await notifier.sync(Game.starRail);
    repository.syncGate?.complete();
    await first;

    expect(repository.syncCalls, [Game.genshin]);
  });

  test('a failed sync clears the syncing flag and rethrows', () async {
    repository.syncError = const AuthkeyExpiredException();

    await expectLater(
      container.read(gachaSyncProvider.notifier).sync(Game.genshin),
      throwsA(isA<AuthkeyExpiredException>()),
    );
    expect(container.read(gachaSyncProvider).syncing, isNull);
    expect(container.read(gachaSyncProvider).lastSynced, isEmpty);
  });

  test('importLink stores the link then syncs its game', () async {
    final game = await container
        .read(gachaSyncProvider.notifier)
        .importLink(genshinLink());

    expect(game, Game.genshin);
    expect(repository.syncCalls, [Game.genshin]);
  });
}
