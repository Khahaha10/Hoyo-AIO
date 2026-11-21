import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/checkin/data/check_in_history_repository_impl.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_record.dart';

CheckInRecord _record(
  Game game,
  DateTime runAt, {
  CheckInResult result = CheckInResult.claimed,
  String? reward,
}) => CheckInRecord(
  accountId: '800000001',
  game: game,
  day:
      '${runAt.year}-${runAt.month.toString().padLeft(2, '0')}-'
      '${runAt.day.toString().padLeft(2, '0')}',
  result: result,
  runAt: runAt,
  reward: reward,
);

void main() {
  late AppDatabase db;
  late CheckInHistoryRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = CheckInHistoryRepositoryImpl(db);
    final created = DateTime(2026);
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: '800000001',
            nickname: 'Tester',
            status: AccountStatus.valid,
            createdAt: created,
            updatedAt: created,
          ),
        );
  });

  tearDown(() => db.close());

  test('addAll stores records that recordsOn and hasRunOn find', () async {
    final at = DateTime.now().subtract(const Duration(hours: 1));
    final records = [
      _record(Game.genshin, at, reward: 'Primogem ×20'),
      _record(Game.zzz, at, result: CheckInResult.captcha),
    ];

    await repository.addAll(records);

    final day = records.first.day;
    expect(await repository.hasRunOn(day), isTrue);
    expect(await repository.hasRunOn('1999-01-01'), isFalse);
    final stored = await repository.recordsOn(day);
    expect(stored.map((r) => (r.game, r.result, r.reward)), [
      (Game.genshin, CheckInResult.claimed, 'Primogem ×20'),
      (Game.zzz, CheckInResult.captcha, null),
    ]);
  });

  test(
    'watchRuns groups by run time, newest first, within the window',
    () async {
      final now = DateTime.now();
      final older = now.subtract(const Duration(days: 2));
      final newer = now.subtract(const Duration(hours: 1));
      final expired = now.subtract(const Duration(days: 40));
      await repository.addAll([
        _record(Game.genshin, older),
        _record(Game.starRail, older),
      ]);
      await repository.addAll([_record(Game.genshin, newer)]);
      await repository.addAll([_record(Game.hi3, expired)]);

      final runs = await repository.watchRuns(limit: 10).first;

      expect(runs.map((r) => r.records.length), [1, 2]);
      expect(runs.first.runAt.isAfter(runs.last.runAt), isTrue);
      expect(runs.last.records.map((r) => r.game), [
        Game.genshin,
        Game.starRail,
      ]);
    },
  );

  test('watchRuns honours the limit', () async {
    final now = DateTime.now();
    for (var i = 1; i <= 3; i++) {
      await repository.addAll([
        _record(Game.genshin, now.subtract(Duration(hours: i))),
      ]);
    }

    final runs = await repository.watchRuns(limit: 2).first;

    expect(runs, hasLength(2));
  });

  test(
    'settings start with every game and follow game toggles in enum order',
    () async {
      final initial = await repository.watchSettings().first;

      await repository.setGameEnabled(Game.starRail, enabled: false);
      await repository.setGameEnabled(Game.hi3, enabled: false);
      await repository.setGameEnabled(Game.genshin, enabled: true);
      await repository.setGameEnabled(Game.genshin, enabled: true);
      final enabled = await repository.watchSettings().first;
      await repository.setGameEnabled(Game.zzz, enabled: false);
      final disabled = await repository.watchSettings().first;

      expect(initial.games, Game.values.toSet());
      expect(enabled.games, {Game.genshin, Game.zzz});
      expect(disabled.games, {Game.genshin});
      final row = await db.select(db.appSettings).getSingle();
      expect(row.autoCheckInGames, 'genshin');
    },
  );

  test('setRunAtMinutes updates the run time', () async {
    await repository.setRunAtMinutes(6 * 60 + 30);

    final settings = await repository.watchSettings().first;

    expect(settings.runAtMinutes, 390);
  });

  test('unknown game names in settings are ignored', () async {
    await db
        .update(db.appSettings)
        .write(
          const AppSettingsCompanion(autoCheckInGames: Value('genshin, nope,')),
        );

    final settings = await repository.watchSettings().first;

    expect(settings.games, {Game.genshin});
  });
}
