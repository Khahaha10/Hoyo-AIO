import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/features/notifications/data/notification_settings_repository_impl.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_settings.dart';

void main() {
  late AppDatabase db;
  late NotificationSettingsRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = NotificationSettingsRepositoryImpl(db);
  });

  tearDown(() => db.close());

  Future<void> writeRaw(String raw) => db
      .update(db.appSettings)
      .write(AppSettingsCompanion(notificationSettings: Value(raw)));

  test('a fresh database reads the defaults', () async {
    expect(await repository.read(), const NotificationSettings());
  });

  test('save round-trips through read and watch', () async {
    const settings = NotificationSettings(
      staminaThresholdPercent: 75,
      dailyReminder: true,
      quietHours: true,
      quietStartMinutes: 60,
    );

    await repository.save(settings);

    expect(await repository.read(), settings);
    expect(await repository.watch().first, settings);
  });

  final badValues = {
    'invalid JSON': '{not json',
    'a JSON list': '[1, 2]',
    'a wrongly typed field': '{"enabled": "yes"}',
    'an empty string': '',
  };
  for (final MapEntry(key: name, value: raw) in badValues.entries) {
    test('falls back to defaults for $name', () async {
      await writeRaw(raw);

      expect(await repository.read(), const NotificationSettings());
    });
  }

  test('keeps known fields and defaults the missing ones', () async {
    await writeRaw('{"stamina": false, "unknown": 1}');

    final settings = await repository.read();

    expect(settings.stamina, isFalse);
    expect(settings.expeditions, isTrue);
  });
}
