import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/database/tables.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    GameRoles,
    NoteSnapshots,
    CheckInHistory,
    WidgetConfigs,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openDefault());

  static const fileName = 'hoyo_aio';

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await into(appSettings).insert(const AppSettingsCompanion(id: Value(1)));
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(appSettings, appSettings.autoCheckInGames);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> markAccountExpired(String accountId) =>
      (update(accounts)..where(
            (a) =>
                a.id.equals(accountId) &
                a.status.equalsValue(AccountStatus.valid),
          ))
          .write(
            AccountsCompanion(
              status: const Value(AccountStatus.expired),
              updatedAt: Value(DateTime.now()),
            ),
          );

  static QueryExecutor _openDefault() => driftDatabase(
    name: fileName,
    native: const DriftNativeOptions(shareAcrossIsolates: true),
  );
}

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
