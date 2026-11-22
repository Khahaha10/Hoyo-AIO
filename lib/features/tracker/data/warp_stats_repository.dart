import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio_provider.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/databook/data/json_view.dart';
import 'package:hoyo_aio/features/tracker/data/warp_stats_remote_source.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_record.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'warp_stats_repository.g.dart';

class WarpStatsRepository {
  const WarpStatsRepository(this._remote);

  final WarpStatsRemoteSource _remote;

  Future<BannerPity?> banner(SavedRole role, String banner) async {
    final gachaType = HoyolabConfig.warpGachaTypes[banner];
    if (gachaType == null) return null;
    final rows = await _remote.fiveStarRows(role, gachaType);
    final limited = HoyolabConfig.gachaLimitedBanners.contains(
      '${Game.starRail.name}.$banner',
    );
    return _pity(role, banner, rows, limited: limited);
  }

  static BannerPity _pity(
    SavedRole role,
    String banner,
    List<Json> rows, {
    required bool limited,
  }) {
    final pity = rows
        .where((row) => !row['got_item'].boolValue)
        .map((row) => row['gacha_count'].intValue)
        .firstOrNull;
    final obtained = [
      for (final row in rows)
        if (row['got_item'].boolValue) row,
    ]..sort((a, b) => a['id'].intValue.compareTo(b['id'].intValue));
    var guaranteed = false;
    final pulls = <FiveStarPull>[];
    for (final row in obtained) {
      final isUp = row['is_up'].boolValue;
      final result = limited
          ? (guaranteed
                ? FiftyFifty.guaranteed
                : isUp
                ? FiftyFifty.won
                : FiftyFifty.lost)
          : null;
      if (limited) guaranteed = !isUp;
      final item = row['item'];
      pulls.add(
        FiveStarPull(
          record: GachaRecord(
            game: Game.starRail,
            id: row['id'].intValue,
            uid: role.uid,
            banner: banner,
            name: item['name'].stringValue,
            itemType: item['item_type'].stringValue,
            rank: BannerPity.fiveStar,
            time: '',
          ),
          pulls: row['gacha_count'].intValue,
          fiftyFifty: result,
        ),
      );
    }
    final since = pity ?? 0;
    return BannerPity(
      banner: banner,
      total: since + pulls.fold<int>(0, (sum, pull) => sum + pull.pulls),
      pity5: since,
      pity4: 0,
      guaranteed: guaranteed,
      fiveStars: pulls.reversed.toList(),
      rowPity: const {},
    );
  }
}

@Riverpod(keepAlive: true)
WarpStatsRepository warpStatsRepository(Ref ref) =>
    WarpStatsRepository(WarpStatsRemoteSource(ref.watch(hoyolabDioProvider)));
