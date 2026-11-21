import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio_provider.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';
import 'package:hoyo_aio/features/codes/domain/codes_repository.dart';
import 'package:hoyo_aio/features/codes/domain/redeem_code.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'codes_repository_impl.g.dart';

typedef ListedCode = ({String code, List<int> rewards, DateTime? expiresAt});

class CodesRepositoryImpl implements CodesRepository {
  CodesRepositoryImpl(this._dio, this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const _millisPerSecond = 1000;

  final Dio _dio;
  final AppDatabase _db;
  final DateTime Function() _now;

  @override
  Future<List<RedeemCode>> refresh() async {
    final firstRun = await _isEmpty();
    final added = <RedeemCode>[];
    for (final MapEntry(key: game, value: gameId)
        in HoyolabConfig.communityGameIds.entries) {
      final listed = await _fetch(gameId);
      added.addAll(await _store(game, listed, markRead: firstRun));
    }
    return firstRun ? const [] : added;
  }

  @override
  Stream<List<RedeemCode>> watch() =>
      (_db.select(_db.seenCodes)
            ..orderBy([(row) => OrderingTerm.desc(row.firstSeenAt)]))
          .map(_toEntity)
          .watch();

  @override
  Future<void> markAllRead() =>
      (_db.update(_db.seenCodes)..where((row) => row.readAt.isNull())).write(
        SeenCodesCompanion(readAt: Value(_now())),
      );

  @override
  Future<void> markRedeemed(Game game, String code) =>
      (_db.update(
            _db.seenCodes,
          )..where((row) => row.game.equalsValue(game) & row.code.equals(code)))
          .write(SeenCodesCompanion(redeemedAt: Value(_now())));

  Future<bool> _isEmpty() async =>
      await (_db.select(_db.seenCodes)..limit(1)).getSingleOrNull() == null;

  Future<List<ListedCode>> _fetch(int gameId) async {
    final response = await guardHoyolab(
      () => _dio.getUri<Map<String, dynamic>>(
        Uri.https(HoyolabConfig.communityHost, HoyolabConfig.codesPath, {
          'game_id': '$gameId',
        }),
        options: communityOptions(),
      ),
    );
    final modules = switch (response.data?['data']) {
      {'modules': final List<dynamic> modules} => modules,
      _ => const <dynamic>[],
    };
    return [
      for (final module in modules)
        if (module case {
          'module_type': HoyolabConfig.codesModuleType,
          'exchange_group': {'bonuses': final List<dynamic> bonuses},
        })
          for (final bonus in bonuses) ?_parseCode(bonus),
    ];
  }

  static ListedCode? _parseCode(Object? bonus) {
    if (bonus
        case {
          'exchange_code': final String code,
          'code_status': final String status,
        }
        when code.isNotEmpty && status == 'ON') {
      final offline = switch (bonus['offline_at']) {
        final int seconds when seconds > 0 =>
          DateTime.fromMillisecondsSinceEpoch(seconds * _millisPerSecond),
        _ => null,
      };
      final rewards = switch (bonus['icon_bonuses']) {
        final List<dynamic> items => [
          for (final item in items)
            if (item case {'bonus_num': final int amount}) amount,
        ],
        _ => const <int>[],
      };
      return (code: code, rewards: rewards, expiresAt: offline);
    }
    return null;
  }

  Future<List<RedeemCode>> _store(
    Game game,
    List<ListedCode> listed, {
    required bool markRead,
  }) => _db.transaction(() async {
    final now = _now();
    final existing = {
      for (final row in await (_db.select(
        _db.seenCodes,
      )..where((row) => row.game.equalsValue(game))).get())
        row.code: row,
    };
    final added = <RedeemCode>[];
    for (final item in listed) {
      final companion = SeenCodesCompanion(
        game: Value(game),
        code: Value(item.code),
        rewards: Value(jsonEncode(item.rewards)),
        expiresAt: Value(item.expiresAt),
        active: const Value(true),
      );
      if (existing.containsKey(item.code)) {
        await (_db.update(_db.seenCodes)..where(
              (row) => row.game.equalsValue(game) & row.code.equals(item.code),
            ))
            .write(companion);
        continue;
      }
      final row = companion.copyWith(
        firstSeenAt: Value(now),
        readAt: Value(markRead ? now : null),
      );
      await _db.into(_db.seenCodes).insert(row);
      added.add(
        RedeemCode(
          game: game,
          code: item.code,
          rewards: item.rewards,
          active: true,
          firstSeenAt: now,
          unread: !markRead,
          expiresAt: item.expiresAt,
        ),
      );
    }
    final listedCodes = {for (final item in listed) item.code};
    for (final code in existing.keys) {
      if (listedCodes.contains(code)) continue;
      await (_db.update(
            _db.seenCodes,
          )..where((row) => row.game.equalsValue(game) & row.code.equals(code)))
          .write(const SeenCodesCompanion(active: Value(false)));
    }
    return added;
  });

  static RedeemCode _toEntity(SeenCode row) => RedeemCode(
    game: row.game,
    code: row.code,
    rewards: _decodeRewards(row.rewards),
    active: row.active,
    firstSeenAt: row.firstSeenAt,
    unread: row.readAt == null,
    expiresAt: row.expiresAt,
    redeemedAt: row.redeemedAt,
  );

  static List<int> _decodeRewards(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is List
          ? [
              for (final item in decoded)
                if (item is int) item,
            ]
          : const [];
    } on FormatException {
      return const [];
    }
  }
}

@Riverpod(keepAlive: true)
CodesRepository codesRepository(Ref ref) => CodesRepositoryImpl(
  ref.watch(hoyolabDioProvider),
  ref.watch(appDatabaseProvider),
);

@Riverpod(keepAlive: true)
Stream<List<RedeemCode>> redeemCodes(Ref ref) =>
    ref.watch(codesRepositoryProvider).watch();

@Riverpod(keepAlive: true)
int unreadCodes(Ref ref) {
  final now = DateTime.now();
  return ref
          .watch(redeemCodesProvider)
          .value
          ?.where((code) => code.unread && !code.isExpiredAt(now))
          .length ??
      0;
}

Uri redeemUri(Game game, String code) =>
    Uri.parse('${HoyolabConfig.redeemUrls[game] ?? ''}$code');
