import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/accounts/domain/account_summary.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/dashboard/data/notes_mapper.dart';
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';
import 'package:hoyo_aio/features/dashboard/domain/note_result.dart';
import 'package:hoyo_aio/features/dashboard/domain/notes_repository.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_record.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_repository.dart';

final fixedNow = DateTime.utc(2026, 11, 21, 10);

const fakeAccountId = '800000001';

Map<String, dynamic> loadNoteFixture(Game game) {
  final name = switch (game) {
    Game.genshin => 'notes_genshin',
    Game.starRail => 'notes_star_rail',
    Game.zzz => 'notes_zzz',
    Game.hi3 => throw ArgumentError.value(game),
  };
  final decoded = jsonDecode(
    File('test/fixtures/$name.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return decoded['data'] as Map<String, dynamic>;
}

GameNote fixtureNote(Game game, {DateTime? fetchedAt}) =>
    NotesMapper.fromJson(game, loadNoteFixture(game), fetchedAt ?? fixedNow);

SavedRole fakeRole(
  Game game, {
  int? id,
  String accountId = fakeAccountId,
  bool enabled = true,
}) => SavedRole(
  id: id ?? game.index + 1,
  accountId: accountId,
  game: game,
  uid: '80000000${game.index + 1}',
  server: 'os_asia',
  nickname: 'Traveler',
  level: 60,
  enabled: enabled,
);

AccountSummary fakeAccount({
  String id = fakeAccountId,
  String nickname = 'Tester',
  AccountStatus status = AccountStatus.valid,
  List<SavedRole>? roles,
}) => AccountSummary(
  id: id,
  nickname: nickname,
  status: status,
  updatedAt: fixedNow,
  roles: roles ?? [for (final game in Game.values) fakeRole(game)],
);

Future<void> insertRoleRows(AppDatabase db, SavedRole role) async {
  await db
      .into(db.accounts)
      .insertOnConflictUpdate(
        AccountsCompanion.insert(
          id: role.accountId,
          nickname: 'Tester',
          status: AccountStatus.valid,
          createdAt: fixedNow,
          updatedAt: fixedNow,
        ),
      );
  await db
      .into(db.gameRoles)
      .insert(
        GameRolesCompanion.insert(
          id: Value(role.id),
          accountId: role.accountId,
          game: role.game,
          uid: role.uid,
          server: role.server,
          nickname: role.nickname,
          level: role.level,
        ),
      );
}

class FakeNotesRepository implements NotesRepository {
  final cachedResults = <int, NoteResult>{};
  final refreshResults = <int, NoteResult>{};
  final refreshErrors = <int, Object>{};
  final refreshed = <SavedRole>[];
  final cachedCalls = <SavedRole>[];

  @override
  Future<NoteResult?> cached(SavedRole role) async {
    cachedCalls.add(role);
    return cachedResults[role.id];
  }

  @override
  Future<NoteResult> refresh(SavedRole role) async {
    refreshed.add(role);
    final error = refreshErrors[role.id];
    if (error != null) throw error;
    final result = refreshResults[role.id] ?? cachedResults[role.id];
    if (result == null) throw StateError('no result for ${role.id}');
    return result;
  }
}

class EmptyGachaRepository implements GachaRepository {
  @override
  Future<Game> importLink(String raw) async => Game.genshin;

  @override
  Future<DateTime?> linkExpiresAt(Game game) async => null;

  @override
  Future<int> sync(Game game, {void Function(int fetched)? onProgress}) async =>
      0;

  @override
  Stream<List<GachaRecord>> watch(Game game) => Stream.value(const []);
}
