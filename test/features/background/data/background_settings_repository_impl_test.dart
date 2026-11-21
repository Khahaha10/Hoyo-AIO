import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/features/background/data/background_settings_repository_impl.dart';

void main() {
  late AppDatabase db;
  late BackgroundSettingsRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    repository = BackgroundSettingsRepositoryImpl(db);
  });

  test('defaults the refresh interval to 30 minutes', () async {
    expect(await repository.watchRefreshMinutes().first, 30);
  });

  test('persists a new refresh interval', () async {
    await repository.setRefreshMinutes(120);

    expect(await repository.watchRefreshMinutes().first, 120);
  });

  test('streams interval changes', () async {
    final values = <int>[];
    final subscription = repository.watchRefreshMinutes().listen(values.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    await repository.setRefreshMinutes(60);
    await pumpEventQueue();

    expect(values, [30, 60]);
  });

  test('refreshMinutesProvider reads from the database', () async {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await container
        .read(backgroundSettingsRepositoryProvider)
        .setRefreshMinutes(15);
    container.listen(refreshMinutesProvider, (_, _) {});

    expect(await container.read(refreshMinutesProvider.future), 15);
  });
}
