import 'package:drift/drift.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/features/background/domain/background_settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'background_settings_repository_impl.g.dart';

class BackgroundSettingsRepositoryImpl implements BackgroundSettingsRepository {
  const BackgroundSettingsRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<int> watchRefreshMinutes() =>
      (_db.select(_db.appSettings)..where((s) => s.id.equals(1)))
          .watchSingle()
          .map((row) => row.refreshIntervalMinutes);

  @override
  Future<void> setRefreshMinutes(int minutes) =>
      (_db.update(_db.appSettings)..where((s) => s.id.equals(1))).write(
        AppSettingsCompanion(refreshIntervalMinutes: Value(minutes)),
      );
}

@Riverpod(keepAlive: true)
BackgroundSettingsRepository backgroundSettingsRepository(Ref ref) =>
    BackgroundSettingsRepositoryImpl(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
Stream<int> refreshMinutes(Ref ref) =>
    ref.watch(backgroundSettingsRepositoryProvider).watchRefreshMinutes();
