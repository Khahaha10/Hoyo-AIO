import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio_provider.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';
import 'package:hoyo_aio/features/events/domain/events_repository.dart';
import 'package:hoyo_aio/features/events/domain/web_event.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'events_repository_impl.g.dart';

typedef ListedEvent = ({
  String id,
  String name,
  String summary,
  DateTime startAt,
  DateTime endAt,
  String webPath,
});

class EventsRepositoryImpl implements EventsRepository {
  EventsRepositoryImpl(this._dio, this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const _millisPerSecond = 1000;

  final Dio _dio;
  final AppDatabase _db;
  final DateTime Function() _now;

  @override
  Future<List<WebEvent>> refresh() async {
    final firstRun =
        await (_db.select(_db.seenEvents)..limit(1)).getSingleOrNull() == null;
    final added = <WebEvent>[];
    for (final MapEntry(key: game, value: gameId)
        in HoyolabConfig.communityGameIds.entries) {
      final listed = await _fetch(gameId);
      added.addAll(await _store(game, listed, markRead: firstRun));
    }
    return firstRun ? const [] : added;
  }

  @override
  Stream<List<WebEvent>> watch() => (_db.select(
    _db.seenEvents,
  )..orderBy([(row) => OrderingTerm.asc(row.endAt)])).map(_toEntity).watch();

  @override
  Future<void> markAllRead() =>
      (_db.update(_db.seenEvents)..where((row) => row.readAt.isNull())).write(
        SeenEventsCompanion(readAt: Value(_now())),
      );

  @override
  Future<void> setRemind(String id, {required bool remind}) =>
      (_db.update(_db.seenEvents)..where((row) => row.id.equals(id))).write(
        SeenEventsCompanion(remind: Value(remind)),
      );

  @override
  Future<List<WebEvent>> takeEndingSoon(Duration within) =>
      _db.transaction(() async {
        final now = _now();
        final rows =
            await (_db.select(_db.seenEvents)..where(
                  (row) =>
                      row.remind.equals(true) &
                      row.endingNotifiedAt.isNull() &
                      row.endAt.isBiggerThanValue(now) &
                      row.endAt.isSmallerOrEqualValue(now.add(within)),
                ))
                .get();
        for (final row in rows) {
          await (_db.update(_db.seenEvents)
                ..where((event) => event.id.equals(row.id)))
              .write(SeenEventsCompanion(endingNotifiedAt: Value(now)));
        }
        return rows.map(_toEntity).toList();
      });

  Future<List<ListedEvent>> _fetch(int gameId) async {
    final response = await guardHoyolab(
      () => _dio.getUri<Map<String, dynamic>>(
        Uri.https(HoyolabConfig.communityHost, HoyolabConfig.eventsPath, {
          'gids': '$gameId',
          'size': '${HoyolabConfig.eventsPageSize}',
        }),
        options: communityOptions(),
      ),
    );
    final list = switch (response.data?['data']) {
      {'list': final List<dynamic> list} => list,
      _ => const <dynamic>[],
    };
    return [for (final item in list) ?_parse(item)];
  }

  static ListedEvent? _parse(Object? item) {
    if (item case {
      'id': final String id,
      'name': final String name,
      'start': final Object start,
      'end': final Object end,
      'web_path': final String webPath,
    }) {
      final startAt = _seconds(start);
      final endAt = _seconds(end);
      if (startAt == null || endAt == null || id.isEmpty) return null;
      return (
        id: id,
        name: name,
        summary: item['desc'] is String ? item['desc'] as String : '',
        startAt: startAt,
        endAt: endAt,
        webPath: webPath,
      );
    }
    return null;
  }

  static DateTime? _seconds(Object value) {
    final seconds = switch (value) {
      final int number => number,
      final String text => int.tryParse(text),
      _ => null,
    };
    return seconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(seconds * _millisPerSecond);
  }

  Future<List<WebEvent>> _store(
    Game game,
    List<ListedEvent> listed, {
    required bool markRead,
  }) => _db.transaction(() async {
    final now = _now();
    final existing = {
      for (final row in await (_db.select(
        _db.seenEvents,
      )..where((row) => row.game.equalsValue(game))).get())
        row.id: row,
    };
    final added = <WebEvent>[];
    for (final item in listed) {
      final companion = SeenEventsCompanion(
        id: Value(item.id),
        game: Value(game),
        name: Value(item.name),
        summary: Value(item.summary),
        startAt: Value(item.startAt),
        endAt: Value(item.endAt),
        webPath: Value(item.webPath),
        active: const Value(true),
      );
      if (existing.containsKey(item.id)) {
        await (_db.update(
          _db.seenEvents,
        )..where((row) => row.id.equals(item.id))).write(companion);
        continue;
      }
      await _db
          .into(_db.seenEvents)
          .insert(
            companion.copyWith(
              firstSeenAt: Value(now),
              readAt: Value(markRead ? now : null),
            ),
          );
      if (item.endAt.isAfter(now)) {
        added.add(
          _toEntity(
            SeenEvent(
              id: item.id,
              game: game,
              name: item.name,
              summary: item.summary,
              startAt: item.startAt,
              endAt: item.endAt,
              webPath: item.webPath,
              active: true,
              remind: false,
              firstSeenAt: now,
              readAt: markRead ? now : null,
            ),
          ),
        );
      }
    }
    final listedIds = {for (final item in listed) item.id};
    for (final id in existing.keys) {
      if (listedIds.contains(id)) continue;
      await (_db.update(_db.seenEvents)..where((row) => row.id.equals(id)))
          .write(const SeenEventsCompanion(active: Value(false)));
    }
    return added;
  });

  static WebEvent _toEntity(SeenEvent row) => WebEvent(
    id: row.id,
    game: row.game,
    name: row.name,
    summary: row.summary,
    startAt: row.startAt,
    endAt: row.endAt,
    webPath: row.webPath,
    active: row.active,
    remind: row.remind,
    unread: row.readAt == null,
    firstSeenAt: row.firstSeenAt,
  );
}

@Riverpod(keepAlive: true)
EventsRepository eventsRepository(Ref ref) => EventsRepositoryImpl(
  ref.watch(hoyolabDioProvider),
  ref.watch(appDatabaseProvider),
);

@Riverpod(keepAlive: true)
Stream<List<WebEvent>> webEvents(Ref ref) =>
    ref.watch(eventsRepositoryProvider).watch();

@Riverpod(keepAlive: true)
int unreadEvents(Ref ref) {
  final now = DateTime.now();
  return ref
          .watch(webEventsProvider)
          .value
          ?.where(
            (event) => event.unread && event.phaseAt(now) != EventPhase.ended,
          )
          .length ??
      0;
}

Uri eventUri(WebEvent event) =>
    Uri.parse('${HoyolabConfig.hoyolabWebUrl}${event.webPath}');
