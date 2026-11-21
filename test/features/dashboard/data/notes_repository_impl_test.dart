import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/dashboard/data/notes_remote_source.dart';
import 'package:hoyo_aio/features/dashboard/data/notes_repository_impl.dart';
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';
import 'package:mocktail/mocktail.dart';

import '../_support/dashboard_fakes.dart';

class _MockRemote extends Mock implements NotesRemoteSource {}

void main() {
  late AppDatabase db;
  late _MockRemote remote;
  late NotesRepositoryImpl repository;
  late DateTime now;
  final role = fakeRole(Game.genshin);

  setUpAll(() => registerFallbackValue(role));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    remote = _MockRemote();
    now = fixedNow;
    repository = NotesRepositoryImpl(remote, db, now: () => now);
    await insertRoleRows(db, role);
  });

  Future<void> seedSnapshot(SavedRole role, String payload, {Game? game}) => db
      .into(db.noteSnapshots)
      .insert(
        NoteSnapshotsCompanion.insert(
          roleId: Value(role.id),
          game: game ?? role.game,
          payload: payload,
          fetchedAt: fixedNow.subtract(const Duration(hours: 1)),
        ),
      );

  test('cached returns null without a snapshot', () async {
    expect(await repository.cached(role), isNull);
  });

  test('refresh maps the response and saves a snapshot', () async {
    when(() => remote.fetch(any()))
        .thenAnswer((_) async => loadNoteFixture(Game.genshin));

    final result = await repository.refresh(role);

    expect(result.isStale, isFalse);
    expect(result.error, isNull);
    expect(result.note, isA<GenshinNote>());
    expect(result.note.fetchedAt, fixedNow);
    final cached = await repository.cached(role);
    expect(cached?.note, result.note);
    final row = await db.select(db.noteSnapshots).getSingle();
    expect(jsonDecode(row.payload), loadNoteFixture(Game.genshin));
  });

  test('refresh overwrites an older snapshot', () async {
    await seedSnapshot(role, jsonEncode({'current_resin': 1}));
    when(() => remote.fetch(any()))
        .thenAnswer((_) async => loadNoteFixture(Game.genshin));

    await repository.refresh(role);

    final cached = await repository.cached(role);
    expect(cached?.note.stamina.current, 142);
  });

  test('refresh error with a cache returns the stale snapshot', () async {
    await seedSnapshot(role, jsonEncode(loadNoteFixture(Game.genshin)));
    when(() => remote.fetch(any())).thenThrow(const NetworkException());

    final result = await repository.refresh(role);

    expect(result.isStale, isTrue);
    expect(result.error, isA<NetworkException>());
    expect(result.note.stamina.current, 142);
  });

  test('refresh error without a cache rethrows the AppException', () async {
    when(() => remote.fetch(any())).thenThrow(const CookieExpiredException());

    await expectLater(
      repository.refresh(role),
      throwsA(isA<CookieExpiredException>()),
    );
  });

  test('a malformed response becomes ParseException', () async {
    when(() => remote.fetch(any())).thenAnswer(
      (_) async => {
        'expeditions': ['not a map'],
      },
    );

    await expectLater(repository.refresh(role), throwsA(isA<ParseException>()));
  });

  test('a snapshot failing to save still returns fresh data', () async {
    final orphan = fakeRole(Game.zzz, id: 99);
    when(() => remote.fetch(any()))
        .thenAnswer((_) async => loadNoteFixture(Game.zzz));

    final result = await repository.refresh(orphan);

    expect(result.note, isA<ZzzNote>());
    expect(result.isStale, isFalse);
    expect(result.error, isA<UnknownException>());
  });

  test('ignores snapshots of another game', () async {
    await seedSnapshot(
      role,
      jsonEncode(loadNoteFixture(Game.zzz)),
      game: Game.zzz,
    );

    expect(await repository.cached(role), isNull);
  });

  test('ignores snapshots that are not a JSON object', () async {
    await seedSnapshot(role, '[1, 2]');

    expect(await repository.cached(role), isNull);
  });

  test('ignores snapshots that no longer parse', () async {
    await seedSnapshot(role, jsonEncode({'expeditions': 'oops'}));

    expect(await repository.cached(role), isNull);
  });

  test('wraps database read failures in UnknownException', () async {
    await db.customStatement('DROP TABLE note_snapshots');

    await expectLater(
      repository.cached(role),
      throwsA(isA<UnknownException>()),
    );
  });
}
