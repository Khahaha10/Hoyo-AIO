import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/settings/data/backup_service.dart';
import 'package:hoyo_aio/features/settings/domain/backup_schema.dart';

import '../_support/settings_support.dart';

void main() {
  late AppDatabase db;
  late BackupService service;

  setUp(() {
    db = openSettingsDatabase();
    addTearDown(db.close);
    service = BackupService(db, () => testNow);
  });

  Future<void> insertAccount(String id, AccountStatus status) => db
      .into(db.accounts)
      .insert(
        AccountsCompanion.insert(
          id: id,
          nickname: 'Nick $id',
          status: status,
          createdAt: testNow,
          updatedAt: testNow,
        ),
      );

  Future<int> insertRole(String accountId, Game game, String uid) => db
      .into(db.gameRoles)
      .insert(
        GameRolesCompanion.insert(
          accountId: accountId,
          game: game,
          uid: uid,
          server: 'os_asia',
          nickname: 'Role',
          level: 10,
        ),
      );

  test('provider builds a service from the database and clock', () {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => testNow),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(backupServiceProvider), isA<BackupService>());
  });

  test('read exports settings, accounts, roles and widgets', () async {
    await insertAccount('acc', AccountStatus.valid);
    final roleId = await insertRole('acc', Game.starRail, fakeUid);
    await insertRole('acc', Game.genshin, otherUid);
    await db
        .into(db.widgetConfigs)
        .insert(
          WidgetConfigsCompanion.insert(
            widgetId: const Value(3),
            size: WidgetSize.small,
            accountId: const Value('acc'),
            roleId: Value(roleId),
            theme: WidgetTheme.clear,
            fontSize: WidgetFontSize.small,
            visibleItems: const Value('["resin", 4]'),
            updatedAt: testNow,
          ),
        );
    await db
        .update(db.appSettings)
        .write(
          const AppSettingsCompanion(
            autoCheckInGames: Value('genshin,unknown,zzz'),
            notificationSettings: Value('not json'),
          ),
        );

    final data = await service.read();

    expect(data.exportedAt, testNow);
    expect(data.settings.autoCheckInGames, [Game.genshin, Game.zzz]);
    expect(data.settings.notificationSettings, isEmpty);
    expect(data.accounts.single.roles, hasLength(2));
    final widget = data.widgets.single;
    expect(widget.roleGame, Game.starRail);
    expect(widget.roleUid, fakeUid);
    expect(widget.visibleItems, ['resin']);
  });

  test(
    'read keeps stored notification settings and handles bad items',
    () async {
      await db
          .update(db.appSettings)
          .write(
            const AppSettingsCompanion(
              notificationSettings: Value('{"enabled":false}'),
            ),
          );
      await db
          .into(db.widgetConfigs)
          .insert(
            WidgetConfigsCompanion.insert(
              widgetId: const Value(4),
              size: WidgetSize.large,
              theme: WidgetTheme.light,
              fontSize: WidgetFontSize.medium,
              visibleItems: const Value('{}'),
              updatedAt: testNow,
            ),
          );

      final data = await service.read();

      expect(data.settings.notificationSettings, {'enabled': false});
      expect(data.widgets.single.visibleItems, isEmpty);
      expect(data.widgets.single.roleGame, isNull);
    },
  );

  test('an export never contains cookie or token material', () async {
    await insertAccount('acc', AccountStatus.valid);
    await insertRole('acc', Game.genshin, fakeUid);

    final text = (await service.read()).encode().toLowerCase();

    for (final secret in ['cookie', 'token', 'authkey', 'ltuid', 'ltoken']) {
      expect(text, isNot(contains(secret)), reason: secret);
    }
  });

  test('export then apply on a fresh database round trips', () async {
    await insertAccount('acc', AccountStatus.valid);
    await insertRole('acc', Game.genshin, fakeUid);
    final exported = BackupData.decode((await service.read()).encode());
    final target = openSettingsDatabase();
    addTearDown(target.close);

    final result = await BackupService(target, () => testNow).apply(exported);
    final reread = await BackupService(target, () => testNow).read();

    expect(result.needsLogin, 1);
    expect(reread.accounts.single.roles.single.uid, fakeUid);
  });

  group('apply', () {
    test('new accounts are inserted as needing login', () async {
      final result = await service.apply(sampleBackup());

      final account = await db.select(db.accounts).getSingle();
      expect(result.needsLogin, 1);
      expect(account.id, 'account-1');
      expect(account.status, AccountStatus.needsLogin);
    });

    test('an existing account keeps its status', () async {
      await insertAccount('account-1', AccountStatus.valid);

      await service.apply(sampleBackup());

      final account = await db.select(db.accounts).getSingle();
      expect(account.status, AccountStatus.valid);
    });

    test('an existing account is not counted as needing login', () async {
      await insertAccount('account-1', AccountStatus.valid);

      final result = await service.apply(sampleBackup());

      expect(result.needsLogin, 0);
    });

    test('roles merge by account, game and uid without duplicates', () async {
      await insertAccount('account-1', AccountStatus.valid);
      final existing = await insertRole('account-1', Game.genshin, fakeUid);

      await service.apply(sampleBackup());
      await service.apply(sampleBackup());

      final roles = await db.select(db.gameRoles).get();
      expect(roles, hasLength(1));
      expect(roles.single.id, existing);
      expect(roles.single.level, 60);
      expect(roles.single.nickname, 'Traveler');
    });

    test('widget role is re-linked by game and uid', () async {
      await insertAccount('account-1', AccountStatus.valid);
      await insertRole('account-1', Game.starRail, fakeUid);
      final genshinId = await insertRole('account-1', Game.genshin, fakeUid);

      await service.apply(sampleBackup());

      final widget = await db.select(db.widgetConfigs).getSingle();
      expect(widget.widgetId, 7);
      expect(widget.accountId, 'account-1');
      expect(widget.roleId, genshinId);
      expect(widget.opacity, 0.5);
      expect(jsonDecode(widget.visibleItems), ['resin', 'realm']);
    });

    test('a widget for a missing account gets no account or role', () async {
      final data = sampleBackup();
      final orphan = BackupData(
        exportedAt: data.exportedAt,
        settings: data.settings,
        accounts: const [],
        widgets: data.widgets,
      );

      await service.apply(orphan);

      final widget = await db.select(db.widgetConfigs).getSingle();
      expect(widget.accountId, isNull);
      expect(widget.roleId, isNull);
    });

    test('settings are replaced by the backup', () async {
      await service.apply(sampleBackup());

      final settings = await db.select(db.appSettings).getSingle();
      expect(settings.themeMode, AppThemeMode.dark);
      expect(settings.dynamicColor, isTrue);
      expect(settings.accent, 'neutral');
      expect(settings.localeCode, 'id');
      expect(settings.autoCheckInMinutes, 8 * 60);
      expect(settings.autoCheckInGames, 'genshin,zzz');
      expect(jsonDecode(settings.notificationSettings), {'enabled': false});
      expect(settings.refreshIntervalMinutes, 60);
    });
  });
}
