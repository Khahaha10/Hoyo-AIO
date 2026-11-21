import 'package:drift/drift.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_history_repository.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_record.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'check_in_history_repository_impl.g.dart';

class CheckInHistoryRepositoryImpl implements CheckInHistoryRepository {
  const CheckInHistoryRepositoryImpl(this._db);

  static const _window = Duration(days: 31);
  static const _separator = ',';

  final AppDatabase _db;

  @override
  Future<void> addAll(List<CheckInRecord> records) => _db.batch(
    (batch) => batch.insertAll(_db.checkInHistory, [
      for (final record in records)
        CheckInHistoryCompanion.insert(
          accountId: record.accountId,
          game: record.game,
          day: record.day,
          result: record.result,
          reward: Value(record.reward),
          createdAt: record.runAt,
        ),
    ]),
  );

  @override
  Stream<List<CheckInRun>> watchRuns({required int limit}) {
    final since = DateTime.now().subtract(_window);
    final query = _db.select(_db.checkInHistory)
      ..where((row) => row.createdAt.isBiggerOrEqualValue(since))
      ..orderBy([
        (row) => OrderingTerm.desc(row.createdAt),
        (row) => OrderingTerm.asc(row.id),
      ]);
    return query.watch().map((rows) {
      final runs = <DateTime, List<CheckInRecord>>{};
      for (final row in rows) {
        (runs[row.createdAt] ??= []).add(
          CheckInRecord(
            accountId: row.accountId,
            game: row.game,
            day: row.day,
            result: row.result,
            runAt: row.createdAt,
            reward: row.reward,
          ),
        );
      }
      return [
        for (final MapEntry(:key, :value) in runs.entries.take(limit))
          CheckInRun(runAt: key, records: value),
      ];
    });
  }

  @override
  Stream<AutoCheckInSettings> watchSettings() =>
      (_db.select(
        _db.appSettings,
      )..where((s) => s.id.equals(1))).watchSingle().map(
        (row) => AutoCheckInSettings(
          games: _parseGames(row.autoCheckInGames),
          runAtMinutes: row.autoCheckInMinutes,
        ),
      );

  @override
  Future<void> setGameEnabled(Game game, {required bool enabled}) =>
      _db.transaction(() async {
        final row = await (_db.select(
          _db.appSettings,
        )..where((s) => s.id.equals(1))).getSingle();
        final games = _parseGames(row.autoCheckInGames);
        final next = enabled ? {...games, game} : games.difference({game});
        await _write(
          AppSettingsCompanion(
            autoCheckInGames: Value(
              [
                for (final value in Game.values)
                  if (next.contains(value)) value.name,
              ].join(_separator),
            ),
          ),
        );
      });

  @override
  Future<void> setRunAtMinutes(int minutes) =>
      _write(AppSettingsCompanion(autoCheckInMinutes: Value(minutes)));

  Future<void> _write(AppSettingsCompanion values) =>
      (_db.update(_db.appSettings)..where((s) => s.id.equals(1))).write(values);

  static Set<Game> _parseGames(String raw) => {
    for (final name in raw.split(_separator))
      ?Game.values.asNameMap()[name.trim()],
  };
}

@Riverpod(keepAlive: true)
CheckInHistoryRepository checkInHistoryRepository(Ref ref) =>
    CheckInHistoryRepositoryImpl(ref.watch(appDatabaseProvider));
