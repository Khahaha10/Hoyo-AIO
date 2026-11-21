import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio_provider.dart';
import 'package:hoyo_aio/features/tracker/data/authkey_vault.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_link.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_record.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gacha_repository_impl.g.dart';

class GachaRepositoryImpl implements GachaRepository {
  GachaRepositoryImpl(
    this._dio,
    this._db,
    this._vault, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const _language = 'en';

  final Dio _dio;
  final AppDatabase _db;
  final AuthkeyVault _vault;
  final DateTime Function() _now;

  @override
  Future<Game> importLink(String raw) async {
    final link = GachaLink.parse(raw, _now());
    if (link == null) throw const ParseException('gacha link');
    await _vault.save(link);
    return link.game;
  }

  @override
  Future<DateTime?> linkExpiresAt(Game game) async =>
      (await _vault.read(game, _now()))?.expiresAt;

  @override
  Stream<List<GachaRecord>> watch(Game game) =>
      (_db.select(_db.gachaRecords)
            ..where((row) => row.game.equalsValue(game))
            ..orderBy([(row) => OrderingTerm.desc(row.id)]))
          .map(_toEntity)
          .watch();

  @override
  Future<int> sync(Game game, {void Function(int fetched)? onProgress}) async {
    final link = await _vault.read(game, _now());
    if (link == null) throw const AuthkeyExpiredException();
    var fetched = 0;
    for (final banner in HoyolabConfig.gachaBanners[game] ?? const <String>[]) {
      final latest = await _latestId(game, banner);
      final fresh = <GachaRecordsCompanion>[];
      var endId = 0;
      var page = 1;
      while (true) {
        final items = await _page(link, banner, endId, page);
        if (items.isEmpty) break;
        var reachedKnown = false;
        for (final item in items) {
          if (item.id.value <= latest) {
            reachedKnown = true;
            break;
          }
          fresh.add(item.copyWith(game: Value(game), banner: Value(banner)));
        }
        fetched += items.length;
        onProgress?.call(fetched);
        if (reachedKnown || items.length < HoyolabConfig.gachaPageSize) break;
        endId = items.last.id.value;
        page++;
      }
      await _db.batch(
        (batch) => batch.insertAll(
          _db.gachaRecords,
          fresh,
          mode: InsertMode.insertOrIgnore,
        ),
      );
    }
    return fetched;
  }

  Future<int> _latestId(Game game, String banner) async {
    final max = _db.gachaRecords.id.max();
    final query = _db.selectOnly(_db.gachaRecords)
      ..addColumns([max])
      ..where(
        _db.gachaRecords.game.equalsValue(game) &
            _db.gachaRecords.banner.equals(banner),
      );
    return await query.map((row) => row.read(max)).getSingle() ?? 0;
  }

  Future<List<GachaRecordsCompanion>> _page(
    GachaLink link,
    String banner,
    int endId,
    int page,
  ) async {
    final game = link.game;
    final host = HoyolabConfig.gachaHosts[game];
    final path = HoyolabConfig.gachaPaths[game];
    final bannerParam = HoyolabConfig.gachaBannerParam[game];
    if (host == null || path == null || bannerParam == null) {
      throw ArgumentError.value(game, 'game', 'has no gacha log');
    }
    final Response<Map<String, dynamic>> response;
    try {
      response = await guardHoyolab(
        () => _dio.getUri<Map<String, dynamic>>(
          Uri.https(host, path, {
            ...link.params,
            'game_biz': ?HoyolabConfig.gachaGameBiz[game],
            'lang': _language,
            bannerParam: banner,
            'size': '${HoyolabConfig.gachaPageSize}',
            'page': '$page',
            'end_id': '$endId',
          }),
        ),
      );
    } on CookieExpiredException catch (error) {
      if (HoyolabConfig.gachaExpiredRetcodes.contains(error.retcode)) {
        await _vault.delete(game);
        throw const AuthkeyExpiredException();
      }
      rethrow;
    } on ServerException catch (error) {
      if (HoyolabConfig.gachaExpiredRetcodes.contains(error.retcode)) {
        await _vault.delete(game);
        throw const AuthkeyExpiredException();
      }
      rethrow;
    }
    final list = switch (response.data?['data']) {
      {'list': final List<dynamic> list} => list,
      _ => const <dynamic>[],
    };
    return [for (final item in list) ?_parse(item)];
  }

  static GachaRecordsCompanion? _parse(Object? item) {
    if (item case {
      'id': final String id,
      'uid': final String uid,
      'name': final String name,
      'rank_type': final String rank,
      'time': final String time,
    }) {
      final numericId = int.tryParse(id);
      final numericRank = int.tryParse(rank);
      if (numericId == null || numericRank == null) return null;
      return GachaRecordsCompanion(
        id: Value(numericId),
        uid: Value(uid),
        gachaType: Value(_text(item['gacha_type'])),
        name: Value(name),
        itemType: Value(_text(item['item_type'])),
        rank: Value(numericRank),
        time: Value(time),
      );
    }
    return null;
  }

  static String _text(Object? value) => value is String ? value : '';

  static GachaRecord _toEntity(GachaRecordRow row) => GachaRecord(
    game: row.game,
    id: row.id,
    uid: row.uid,
    banner: row.banner,
    name: row.name,
    itemType: row.itemType,
    rank: row.rank,
    time: row.time,
  );
}

@Riverpod(keepAlive: true)
GachaRepository gachaRepository(Ref ref) => GachaRepositoryImpl(
  ref.watch(hoyolabDioProvider),
  ref.watch(appDatabaseProvider),
  ref.watch(authkeyVaultProvider),
);
