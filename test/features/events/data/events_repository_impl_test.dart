import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio_provider.dart';
import 'package:hoyo_aio/features/events/data/events_repository_impl.dart';

import '../../codes/_support/community_fakes.dart';
import '../../tracker/_support/tracker_support.dart';

Map<String, Object?> listedEvent(
  String id, {
  required Duration start,
  required Duration end,
  bool asString = false,
  String? desc = 'About it',
}) {
  int seconds(Duration offset) =>
      testNow.add(offset).millisecondsSinceEpoch ~/ 1000;
  return {
    'id': id,
    'name': 'Event $id',
    'desc': ?desc,
    'start': asString ? '${seconds(start)}' : seconds(start),
    'end': asString ? '${seconds(end)}' : seconds(end),
    'web_path': '/article/$id',
  };
}

void main() {
  const day = Duration(days: 1);
  const hour = Duration(hours: 1);

  late AppDatabase db;
  late Map<Game, List<Object?>> listing;
  late DateTime now;
  late EventsRepositoryImpl repository;
  final gameById = {
    for (final MapEntry(:key, :value) in HoyolabConfig.communityGameIds.entries)
      '$value': key,
  };

  Object? handle(RequestOptions options) => {
    'retcode': 0,
    'data': {'list': listing[gameById[options.uri.queryParameters['gids']]]},
  };

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    listing = {};
    now = testNow;
    repository = EventsRepositoryImpl(fakeDio(handle), db, now: () => now);
  });

  test('first run stores events silently as read', () async {
    listing[Game.genshin] = [listedEvent('1', start: -day, end: day)];

    expect(await repository.refresh(), isEmpty);

    final stored = await repository.watch().first;
    expect(stored.single.unread, isFalse);
    expect(stored.single.summary, 'About it');
  });

  test('a new event later produces one new item, ended ones none', () async {
    listing[Game.genshin] = [listedEvent('1', start: -day, end: day)];
    await repository.refresh();
    listing[Game.zzz] = [
      listedEvent('2', start: day, end: day * 3, asString: true, desc: null),
      listedEvent('3', start: -day * 3, end: -day),
    ];

    final added = await repository.refresh();
    final again = await repository.refresh();

    expect(added.map((event) => event.id), ['2']);
    expect(added.single.unread, isTrue);
    expect(added.single.summary, '');
    expect(again, isEmpty);
    expect(await repository.watch().first, hasLength(3));
  });

  test('skips malformed events', () async {
    listing[Game.genshin] = [
      listedEvent('', start: -day, end: day),
      {...listedEvent('5', start: -day, end: day), 'start': 'soon'},
      {...listedEvent('6', start: -day, end: day), 'end': 1.5},
      {'id': '7'},
      'not a map',
    ];

    await repository.refresh();

    expect(await repository.watch().first, isEmpty);
  });

  test('watch orders by end time and keeps parsed dates', () async {
    listing[Game.genshin] = [
      listedEvent('late', start: -day, end: day * 5),
      listedEvent('soon', start: -day, end: day),
    ];

    await repository.refresh();

    final stored = await repository.watch().first;
    expect(stored.map((event) => event.id), ['soon', 'late']);
    expect(stored.first.endAt, testNow.add(day));
    expect(stored.first.webPath, '/article/soon');
  });

  test('an event no longer listed becomes inactive', () async {
    listing[Game.genshin] = [listedEvent('1', start: -day, end: day)];
    await repository.refresh();
    listing[Game.genshin] = [];

    await repository.refresh();

    expect((await repository.watch().first).single.active, isFalse);
  });

  test('markAllRead and setRemind update rows', () async {
    listing[Game.genshin] = [listedEvent('1', start: -day, end: day)];
    await repository.refresh();
    listing[Game.genshin] = [
      listedEvent('1', start: -day, end: day),
      listedEvent('2', start: -day, end: day),
    ];
    await repository.refresh();

    await repository.markAllRead();
    await repository.setRemind('2', remind: true);

    final stored = await repository.watch().first;
    expect(stored.where((event) => event.unread), isEmpty);
    expect(stored.firstWhere((event) => event.id == '2').remind, isTrue);
    expect(stored.firstWhere((event) => event.id == '1').remind, isFalse);
  });

  group('takeEndingSoon', () {
    setUp(() async {
      listing[Game.genshin] = [
        listedEvent('soon', start: -day, end: hour * 5),
        listedEvent('quiet', start: -day, end: hour * 5),
        listedEvent('later', start: -day, end: day * 3),
        listedEvent('ended', start: -day * 2, end: -hour),
      ];
      await repository.refresh();
      for (final id in ['soon', 'later', 'ended']) {
        await repository.setRemind(id, remind: true);
      }
    });

    test('returns reminded events ending within 24 hours only once', () async {
      final first = await repository.takeEndingSoon(day);
      final second = await repository.takeEndingSoon(day);

      expect(first.map((event) => event.id), ['soon']);
      expect(second, isEmpty);
    });

    test('later events come up once inside the window', () async {
      await repository.takeEndingSoon(day);
      now = testNow.add(day * 2 + hour);

      final due = await repository.takeEndingSoon(day);

      expect(due.map((event) => event.id), ['later']);
    });
  });

  test('eventUri points at the HoYoLAB web page', () {
    expect(
      eventUri(webEvent('9')).toString(),
      '${HoyolabConfig.hoyolabWebUrl}/article/9',
    );
  });

  group('providers', () {
    test('unreadEvents counts unread events that have not ended', () async {
      final container = ProviderContainer(
        overrides: [
          webEventsProvider.overrideWith(
            (ref) => Stream.value([
              webEvent(
                '1',
                unread: true,
                endOffset: const Duration(days: 9000),
              ),
              webEvent('2', endOffset: const Duration(days: 9000)),
              webEvent(
                '3',
                unread: true,
                startOffset: -const Duration(days: 9000),
                endOffset: -const Duration(days: 8000),
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(unreadEventsProvider, (_, _) {});

      await container.read(webEventsProvider.future);

      expect(container.read(unreadEventsProvider), 1);
    });

    test('repository and stream providers read the database', () async {
      final container = ProviderContainer(
        overrides: [
          hoyolabDioProvider.overrideWithValue(Dio()),
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);
      container.listen(webEventsProvider, (_, _) {});

      expect(
        container.read(eventsRepositoryProvider),
        isA<EventsRepositoryImpl>(),
      );
      expect(await container.read(webEventsProvider.future), isEmpty);
    });
  });
}
