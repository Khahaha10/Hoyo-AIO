import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio_provider.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/dashboard/data/notes_mapper.dart';
import 'package:hoyo_aio/features/dashboard/data/notes_remote_source.dart';
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';
import 'package:hoyo_aio/features/dashboard/domain/note_result.dart';
import 'package:hoyo_aio/features/dashboard/domain/notes_repository.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notes_repository_impl.g.dart';

class NotesRepositoryImpl implements NotesRepository {
  NotesRepositoryImpl(this._remote, this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final NotesRemoteSource _remote;
  final AppDatabase _db;
  final DateTime Function() _now;

  @override
  Future<NoteResult?> cached(SavedRole role) async {
    final note = await _readSnapshot(role);
    return note == null ? null : NoteResult(note: note);
  }

  @override
  Future<NoteResult> refresh(SavedRole role) async {
    final Map<String, dynamic> json;
    final DateTime fetchedAt;
    final GameNote note;
    try {
      json = await _remote.fetch(role);
      fetchedAt = _now();
      note = _map(role, json, fetchedAt);
    } on AppException catch (error) {
      final cached = await _readSnapshot(role);
      if (cached == null) rethrow;
      return NoteResult(note: cached, isStale: true, error: error);
    }
    try {
      await _writeSnapshot(role, json, fetchedAt);
    } on AppException catch (error) {
      return NoteResult(note: note, error: error);
    }
    return NoteResult(note: note);
  }

  GameNote _map(SavedRole role, Map<String, dynamic> json, DateTime at) {
    try {
      return NotesMapper.fromJson(role.game, json, at);
    } on CheckedFromJsonException catch (e) {
      throw ParseException('notes ${role.game.name}: ${e.key}');
    }
  }

  Future<GameNote?> _readSnapshot(SavedRole role) async {
    final NoteSnapshot? row;
    try {
      row = await (_db.select(
        _db.noteSnapshots,
      )..where((s) => s.roleId.equals(role.id))).getSingleOrNull();
    } on Exception catch (e) {
      throw UnknownException('database: ${e.runtimeType}');
    }
    if (row == null || row.game != role.game) return null;
    final decoded = jsonDecode(row.payload);
    if (decoded is! Map<String, dynamic>) return null;
    try {
      return NotesMapper.fromJson(role.game, decoded, row.fetchedAt);
    } on CheckedFromJsonException {
      return null;
    }
  }

  Future<void> _writeSnapshot(
    SavedRole role,
    Map<String, dynamic> json,
    DateTime fetchedAt,
  ) async {
    try {
      await _db
          .into(_db.noteSnapshots)
          .insertOnConflictUpdate(
            NoteSnapshotsCompanion.insert(
              roleId: Value(role.id),
              game: role.game,
              payload: jsonEncode(json),
              fetchedAt: fetchedAt,
            ),
          );
    } on Exception catch (e) {
      throw UnknownException('database: ${e.runtimeType}');
    }
  }
}

@Riverpod(keepAlive: true)
NotesRepository notesRepository(Ref ref) => NotesRepositoryImpl(
  NotesRemoteSource(ref.watch(hoyolabDioProvider)),
  ref.watch(appDatabaseProvider),
);
