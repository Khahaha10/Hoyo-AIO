import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/home_widgets/data/widget_config_repository_impl.dart';

import '../_support/widget_fixtures.dart';

Future<int> _seedRole(AppDatabase db) async {
  final now = DateTime(2026, 11, 21);
  await db
      .into(db.accounts)
      .insert(
        AccountsCompanion.insert(
          id: testAccountId,
          nickname: 'Tester',
          status: AccountStatus.valid,
          createdAt: now,
          updatedAt: now,
        ),
      );
  return db
      .into(db.gameRoles)
      .insert(
        GameRolesCompanion.insert(
          accountId: testAccountId,
          game: Game.genshin,
          uid: '800000001',
          server: 'os_asia',
          nickname: 'Tester1',
          level: 60,
        ),
      );
}

void main() {
  late AppDatabase db;
  late WidgetConfigRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    repository = WidgetConfigRepositoryImpl(db);
  });

  test('saves and reads back a full config', () async {
    final roleId = await _seedRole(db);
    final saved = config(
      roleId: roleId,
      theme: 'clear',
      opacity: 0.5,
      accent: 'lime',
      fontSize: 'large',
      visibleItems: const ['realm', 'transformer'],
    );

    await repository.save(saved, accountId: testAccountId);

    expect(await repository.all(), [saved]);
    final row = await db.select(db.widgetConfigs).getSingle();
    expect(row.accountId, testAccountId);
  });

  test('save updates the same widget id instead of duplicating', () async {
    await repository.save(config(roleId: null), accountId: null);

    await repository.save(config(roleId: null, theme: 'dark'), accountId: null);

    final all = await repository.all();
    expect(all, hasLength(1));
    expect(all.single.theme, 'dark');
  });

  test('watch emits after every save', () async {
    final emitted = repository.watch().map((list) => list.length);

    final expectation = expectLater(emitted, emitsInOrder([0, 1]));
    await pumpEventQueue();
    await repository.save(config(roleId: null), accountId: null);

    await expectation;
  });

  test('reads malformed or non-list visible items as empty', () async {
    await repository.save(config(roleId: null), accountId: null);
    await repository.save(config(widgetId: 8, roleId: null), accountId: null);
    await (db.update(db.widgetConfigs)..where((t) => t.widgetId.equals(7)))
        .write(const WidgetConfigsCompanion(visibleItems: Value('not json')));
    await (db.update(db.widgetConfigs)..where((t) => t.widgetId.equals(8)))
        .write(const WidgetConfigsCompanion(visibleItems: Value('{"a":1}')));

    final all = await repository.all();

    expect(all.map((c) => c.visibleItems), [isEmpty, isEmpty]);
  });

  test('stores no cookie-like column in widget_configs', () {
    final columns = db.widgetConfigs.$columns.map((c) => c.name);

    expect(columns.where((n) => RegExp('cookie|token').hasMatch(n)), isEmpty);
  });
}
