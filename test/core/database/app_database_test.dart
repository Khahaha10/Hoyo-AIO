import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';

AppDatabase _open() => AppDatabase(NativeDatabase.memory());

final _when = DateTime.utc(2026, 11, 21);

Future<void> _addAccount(AppDatabase db, String id) => db
    .into(db.accounts)
    .insert(
      AccountsCompanion.insert(
        id: id,
        nickname: 'Traveler',
        status: AccountStatus.valid,
        createdAt: _when,
        updatedAt: _when,
      ),
    );

Future<int> _addRole(AppDatabase db, String accountId) => db
    .into(db.gameRoles)
    .insert(
      GameRolesCompanion.insert(
        accountId: accountId,
        game: Game.genshin,
        uid: '800000001',
        server: 'os_asia',
        nickname: 'Traveler',
        level: 60,
      ),
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('AppDatabase', () {
    test('creates the single settings row with defaults', () async {
      final db = _open();
      addTearDown(db.close);

      final settings = await db.select(db.appSettings).getSingle();

      expect(settings.id, 1);
      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.onboardingSeen, isFalse);
      expect(settings.accent, 'lime');
      expect(settings.refreshIntervalMinutes, 30);
      expect(db.schemaVersion, 7);
    });

    test('account CRUD and role defaults', () async {
      final db = _open();
      addTearDown(db.close);

      await _addAccount(db, '800000001');
      final roleId = await _addRole(db, '800000001');
      await (db.update(db.accounts)..where((a) => a.id.equals('800000001')))
          .write(const AccountsCompanion(nickname: Value('Renamed')));

      final account = await db.select(db.accounts).getSingle();
      final role = await db.select(db.gameRoles).getSingle();
      expect(account.nickname, 'Renamed');
      expect(role.id, roleId);
      expect(role.enabled, isTrue);
    });

    test(
      'deleting an account cascades to roles, snapshots and history',
      () async {
        final db = _open();
        addTearDown(db.close);
        await _addAccount(db, '800000001');
        final roleId = await _addRole(db, '800000001');
        await db
            .into(db.noteSnapshots)
            .insert(
              NoteSnapshotsCompanion.insert(
                roleId: Value(roleId),
                game: Game.genshin,
                payload: '{}',
                fetchedAt: _when,
              ),
            );
        await db
            .into(db.checkInHistory)
            .insert(
              CheckInHistoryCompanion.insert(
                accountId: '800000001',
                game: Game.genshin,
                day: '2026-11-21',
                result: CheckInResult.claimed,
                createdAt: _when,
              ),
            );
        await db
            .into(db.widgetConfigs)
            .insert(
              WidgetConfigsCompanion.insert(
                widgetId: const Value(7),
                size: WidgetSize.small,
                accountId: const Value('800000001'),
                roleId: Value(roleId),
                theme: WidgetTheme.dark,
                fontSize: WidgetFontSize.medium,
                updatedAt: _when,
              ),
            );

        await (db.delete(
          db.accounts,
        )..where((a) => a.id.equals('800000001'))).go();

        expect(await db.select(db.gameRoles).get(), isEmpty);
        expect(await db.select(db.noteSnapshots).get(), isEmpty);
        expect(await db.select(db.checkInHistory).get(), isEmpty);
        final widget = await db.select(db.widgetConfigs).getSingle();
        expect(widget.accountId, isNull);
        expect(widget.roleId, isNull);
      },
    );

    test('a role id is unique per account, game and uid', () async {
      final db = _open();
      addTearDown(db.close);
      await _addAccount(db, '800000001');
      await _addRole(db, '800000001');

      await expectLater(
        _addRole(db, '800000001'),
        throwsA(isA<SqliteException>()),
      );
    });

    test('markAccountExpired flips only valid accounts', () async {
      final db = _open();
      addTearDown(db.close);
      await _addAccount(db, '800000001');
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: '800000002',
              nickname: 'B',
              status: AccountStatus.needsLogin,
              createdAt: _when,
              updatedAt: _when,
            ),
          );

      await db.markAccountExpired('800000001');
      await db.markAccountExpired('800000002');

      final rows = {
        for (final a in await db.select(db.accounts).get()) a.id: a.status,
      };
      expect(rows['800000001'], AccountStatus.expired);
      expect(rows['800000002'], AccountStatus.needsLogin);
    });

    test('noteSnapshotChanges emits when snapshots are written', () async {
      final db = _open();
      addTearDown(db.close);
      await _addAccount(db, '800000001');
      final roleId = await _addRole(db, '800000001');
      final next = db.noteSnapshotChanges().first;

      await db
          .into(db.noteSnapshots)
          .insert(
            NoteSnapshotsCompanion.insert(
              roleId: Value(roleId),
              game: Game.genshin,
              payload: '{}',
              fetchedAt: _when,
            ),
          );

      expect(await next, isNotEmpty);
    });

    test('codes, events and gacha records round-trip', () async {
      final db = _open();
      addTearDown(db.close);

      await db
          .into(db.seenCodes)
          .insert(
            SeenCodesCompanion.insert(
              game: Game.zzz,
              code: 'FAKECODE',
              firstSeenAt: _when,
            ),
          );
      await db
          .into(db.seenEvents)
          .insert(
            SeenEventsCompanion.insert(
              id: 'e1',
              game: Game.genshin,
              name: 'Event',
              startAt: _when,
              endAt: _when.add(const Duration(days: 7)),
              webPath: '/e1',
              firstSeenAt: _when,
            ),
          );
      await db
          .into(db.gachaRecords)
          .insert(
            GachaRecordsCompanion.insert(
              game: Game.starRail,
              id: 1,
              uid: '800000001',
              banner: '11',
              gachaType: '11',
              name: 'Item',
              itemType: 'Character',
              rank: 5,
              time: '2026-11-21 10:00:00',
            ),
          );

      expect((await db.select(db.seenCodes).getSingle()).active, isTrue);
      expect((await db.select(db.seenEvents).getSingle()).remind, isFalse);
      expect((await db.select(db.gachaRecords).getSingle()).rank, 5);
    });
  });

  group('schema', () {
    test('no column name looks like a cookie, token or authkey', () async {
      final db = _open();
      addTearDown(db.close);
      final secret = RegExp('cookie|token|authkey', caseSensitive: false);

      final columns = [
        for (final table in db.allTables)
          for (final column in table.$columns)
            '${table.actualTableName}.${column.name}',
      ];

      expect(columns, isNotEmpty);
      expect(columns.where(secret.hasMatch), isEmpty);
    });
  });
}
