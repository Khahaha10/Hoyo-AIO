import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio_provider.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/databook/data/chronicle_remote_source.dart';
import 'package:hoyo_aio/features/databook/data/genshin_chronicle_mapper.dart';
import 'package:hoyo_aio/features/databook/data/json_view.dart';
import 'package:hoyo_aio/features/databook/data/server_time.dart';
import 'package:hoyo_aio/features/databook/data/star_rail_chronicle_mapper.dart';
import 'package:hoyo_aio/features/databook/data/zenless_chronicle_mapper.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_repository.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chronicle_repository_impl.g.dart';

class _Loaded {
  const _Loaded(this.data, this.fetchedAt, this.isStale);

  final Json data;
  final DateTime fetchedAt;
  final bool isStale;
}

class ChronicleRepositoryImpl implements ChronicleRepository {
  ChronicleRepositoryImpl(this._remote, this._db, this._now);

  static const maxAge = Duration(minutes: 30);

  static const _summaryKeys = {
    Game.genshin: 'gi.index',
    Game.starRail: 'hsr.index',
    Game.zzz: 'zzz.index',
  };
  static const _characterKeys = {
    Game.genshin: 'gi.characters',
    Game.starRail: 'hsr.characters',
    Game.zzz: 'zzz.agents',
  };
  static const _currentKeys = {
    EndgameMode.spiralAbyss: 'gi.abyss.current',
    EndgameMode.imaginariumTheater: 'gi.theater',
    EndgameMode.stygianOnslaught: 'gi.onslaught',
    EndgameMode.memoryOfChaos: 'hsr.chaos.current',
    EndgameMode.pureFiction: 'hsr.fiction.current',
    EndgameMode.apocalypticShadow: 'hsr.shadow.current',
    EndgameMode.anomalyArbitration: 'hsr.arbitration.current',
    EndgameMode.shiyuDefense: 'zzz.shiyu.current',
    EndgameMode.deadlyAssault: 'zzz.assault.current',
  };
  static const _previousKeys = {
    EndgameMode.spiralAbyss: 'gi.abyss.previous',
    EndgameMode.imaginariumTheater: 'gi.theater',
    EndgameMode.stygianOnslaught: 'gi.onslaught',
    EndgameMode.memoryOfChaos: 'hsr.chaos.previous',
    EndgameMode.pureFiction: 'hsr.fiction.previous',
    EndgameMode.apocalypticShadow: 'hsr.shadow.previous',
    EndgameMode.anomalyArbitration: 'hsr.arbitration.recent',
    EndgameMode.shiyuDefense: 'zzz.shiyu.previous',
    EndgameMode.deadlyAssault: 'zzz.assault.previous',
  };

  final ChronicleRemoteSource _remote;
  final AppDatabase _db;
  final DateTime Function() _now;

  @override
  Future<ChronicleResult<ChronicleSummary>> summary(
    SavedRole role, {
    bool refresh = false,
  }) async {
    final loaded = await _load(role, _key(_summaryKeys, role.game), refresh);
    return _result(loaded, switch (role.game) {
      Game.genshin => GenshinChronicleMapper.summary(loaded.data),
      Game.starRail => StarRailChronicleMapper.summary(loaded.data),
      Game.zzz => ZenlessChronicleMapper.summary(loaded.data),
      Game.hi3 => throw ArgumentError.value(role.game, 'game'),
    });
  }

  @override
  Future<ChronicleResult<List<ChronicleCharacter>>> characters(
    SavedRole role, {
    bool refresh = false,
  }) async {
    final loaded = await _load(role, _key(_characterKeys, role.game), refresh);
    return _result(loaded, switch (role.game) {
      Game.genshin => GenshinChronicleMapper.characters(loaded.data),
      Game.starRail => StarRailChronicleMapper.characters(loaded.data),
      Game.zzz => ZenlessChronicleMapper.characters(loaded.data),
      Game.hi3 => throw ArgumentError.value(role.game, 'game'),
    });
  }

  @override
  Future<ChronicleResult<List<EndgameSummary>>> endgameOverview(
    SavedRole role, {
    bool refresh = false,
  }) async {
    final modes = EndgameMode.forGame(role.game);
    final outcomes = await Future.wait([
      for (final mode in modes)
        _tryLoad(role, _key(_currentKeys, mode), refresh),
    ]);
    final failures = [for (final outcome in outcomes) ?outcome.error];
    if (failures.length == outcomes.length) throw failures.first;
    final privateError = failures.where(isChroniclePrivate).firstOrNull;
    if (privateError != null) throw privateError;
    final now = _now();
    final summaries = <EndgameSummary>[];
    var fetchedAt = now;
    var stale = false;
    for (final (i, outcome) in outcomes.indexed) {
      final loaded = outcome.loaded;
      if (loaded == null) continue;
      summaries.add(_mapSummary(modes[i], role, loaded.data, now));
      if (loaded.fetchedAt.isBefore(fetchedAt)) fetchedAt = loaded.fetchedAt;
      stale = stale || loaded.isStale;
    }
    return ChronicleResult(
      data: summaries,
      fetchedAt: fetchedAt,
      isStale: stale,
    );
  }

  @override
  Future<ChronicleResult<EndgameDetail>> endgameDetail(
    SavedRole role,
    EndgameMode mode, {
    required bool previous,
    bool refresh = false,
  }) async {
    final key = _key(previous ? _previousKeys : _currentKeys, mode);
    final loaded = await _load(role, key, refresh);
    final now = _now();
    final offset = ServerTime.offsetFor(role.game, role.server);
    final detail = switch (role.game) {
      Game.genshin => GenshinChronicleMapper.endgameDetail(
        mode,
        loaded.data,
        now,
        previous: previous,
      ),
      Game.starRail => StarRailChronicleMapper.endgameDetail(
        mode,
        loaded.data,
        offset,
        previous: previous,
        now: now,
      ),
      Game.zzz => ZenlessChronicleMapper.endgameDetail(
        mode,
        loaded.data,
        offset,
      ),
      Game.hi3 => throw ArgumentError.value(role.game, 'game'),
    };
    return _result(loaded, detail);
  }

  @override
  Future<ChronicleResult<CharacterDetail>> characterDetail(
    SavedRole role,
    int characterId, {
    bool refresh = false,
  }) async {
    final id = '$characterId';
    return switch (role.game) {
      Game.genshin => _detailOf(
        await _load(role, 'gi.characterDetail', refresh, entityId: id),
        GenshinChronicleMapper.characterDetail,
      ),
      Game.starRail => _detailOf(
        await _load(role, 'hsr.characters', refresh),
        (data) => StarRailChronicleMapper.characterDetail(data, characterId),
      ),
      Game.zzz => _detailOf(
        await _load(role, 'zzz.agentDetail', refresh, entityId: id),
        ZenlessChronicleMapper.characterDetail,
      ),
      Game.hi3 => throw ArgumentError.value(role.game, 'game'),
    };
  }

  ChronicleResult<CharacterDetail> _detailOf(
    _Loaded loaded,
    CharacterDetail Function(Json data) map,
  ) => _result(loaded, map(loaded.data));

  @override
  Future<void> makePublic(SavedRole role) async {
    await _remote.makePublic(role);
    await (_db.delete(
      _db.chronicleCache,
    )..where((row) => row.roleId.equals(role.id))).go();
  }

  EndgameSummary _mapSummary(
    EndgameMode mode,
    SavedRole role,
    Json data,
    DateTime now,
  ) {
    final offset = ServerTime.offsetFor(role.game, role.server);
    return switch (role.game) {
      Game.genshin => GenshinChronicleMapper.endgameSummary(mode, data, now),
      Game.starRail => StarRailChronicleMapper.endgameSummary(
        mode,
        data,
        offset,
        now: now,
      ),
      Game.zzz => ZenlessChronicleMapper.endgameSummary(mode, data, offset),
      Game.hi3 => throw ArgumentError.value(role.game, 'game'),
    };
  }

  static String _key<K>(Map<K, String> keys, K from) {
    final key = keys[from];
    if (key == null) throw ArgumentError.value(from, 'from', 'no endpoint');
    return key;
  }

  ChronicleResult<T> _result<T>(_Loaded loaded, T data) => ChronicleResult(
    data: data,
    fetchedAt: loaded.fetchedAt,
    isStale: loaded.isStale,
  );

  Future<({_Loaded? loaded, AppException? error})> _tryLoad(
    SavedRole role,
    String key,
    bool refresh,
  ) async {
    try {
      return (loaded: await _load(role, key, refresh), error: null);
    } on AppException catch (error) {
      return (loaded: null, error: error);
    }
  }

  Future<_Loaded> _load(
    SavedRole role,
    String key,
    bool refresh, {
    String? entityId,
  }) async {
    final cacheKey = entityId == null ? key : '$key:$entityId';
    final cached = await _readCache(role, cacheKey);
    final now = _now();
    if (!refresh &&
        cached != null &&
        now.difference(cached.fetchedAt) < maxAge) {
      return _Loaded(Json(cached.data), cached.fetchedAt, false);
    }
    try {
      final fresh = await _remote.fetch(role, key, entityId: entityId);
      await _writeCache(role, cacheKey, fresh.raw, now);
      return _Loaded(fresh, now, false);
    } on AppException {
      if (cached == null) rethrow;
      return _Loaded(Json(cached.data), cached.fetchedAt, true);
    }
  }

  Future<({Object? data, DateTime fetchedAt})?> _readCache(
    SavedRole role,
    String key,
  ) async {
    try {
      final row =
          await (_db.select(_db.chronicleCache)
                ..where((r) => r.roleId.equals(role.id) & r.key.equals(key)))
              .getSingleOrNull();
      if (row == null) return null;
      return (data: jsonDecode(row.payload), fetchedAt: row.fetchedAt);
    } on Exception {
      return null;
    }
  }

  Future<void> _writeCache(
    SavedRole role,
    String key,
    Object? data,
    DateTime at,
  ) async {
    try {
      await _db
          .into(_db.chronicleCache)
          .insertOnConflictUpdate(
            ChronicleCacheCompanion.insert(
              roleId: role.id,
              key: key,
              payload: jsonEncode(data),
              fetchedAt: at,
            ),
          );
    } on Exception catch (e) {
      throw UnknownException('database: ${e.runtimeType}');
    }
  }
}

@Riverpod(keepAlive: true)
ChronicleRepository chronicleRepository(Ref ref) => ChronicleRepositoryImpl(
  ChronicleRemoteSource(ref.watch(hoyolabDioProvider)),
  ref.watch(appDatabaseProvider),
  ref.watch(clockProvider),
);
