import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';

import 'generated/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  for (var from = 1; from < 6; from++) {
    test('upgrades from v$from to v6 with the exported schema', () async {
      final schema = await verifier.schemaAt(from);
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 6);
    });
  }

  test('v1 to v6 keeps accounts and settings and adds defaults', () async {
    final schema = await verifier.schemaAt(1);
    schema.rawDatabase
      ..execute(
        'INSERT INTO accounts (id, nickname, status, created_at, updated_at) '
        "VALUES ('800000001', 'Traveler', 'valid', "
        "'2026-11-01T00:00:00.000', '2026-11-01T00:00:00.000')",
      )
      ..execute(
        'INSERT INTO app_settings (id, onboarding_seen, theme_mode) '
        "VALUES (1, 1, 'dark')",
      );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 6);

    final account = await db.select(db.accounts).getSingle();
    final settings = await db.select(db.appSettings).getSingle();
    expect(account.id, '800000001');
    expect(account.status, AccountStatus.valid);
    expect(settings.onboardingSeen, isTrue);
    expect(settings.themeMode, AppThemeMode.dark);
    expect(settings.autoCheckInGames, 'genshin,starRail,zzz,hi3');
    expect(settings.notificationSettings, '{}');
    expect(await db.select(db.gachaRecords).get(), isEmpty);
  });
}
