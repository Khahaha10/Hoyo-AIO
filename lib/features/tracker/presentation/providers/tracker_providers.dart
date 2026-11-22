import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/tracker/data/gacha_repository_impl.dart';
import 'package:hoyo_aio/features/tracker/data/warp_stats_repository.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_record.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tracker_providers.freezed.dart';
part 'tracker_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<List<GachaRecord>> gachaRecords(Ref ref, Game game) =>
    ref.watch(gachaRepositoryProvider).watch(game);

@riverpod
BannerPity bannerPity(Ref ref, Game game, String banner) {
  final records = ref.watch(gachaRecordsProvider(game)).value ?? const [];
  final limited = HoyolabConfig.gachaLimitedBanners.contains(
    '${game.name}.$banner',
  );
  return BannerPity.of(banner, [
    for (final record in records)
      if (record.banner == banner) record,
  ], standardPool: limited ? HoyolabConfig.gachaStandardPool[game] : null);
}

@riverpod
Future<BannerPity?> warpPity(Ref ref, SavedRole role, String banner) =>
    ref.watch(warpStatsRepositoryProvider).banner(role, banner);

@riverpod
Future<DateTime?> gachaLinkExpiry(Ref ref, Game game) {
  ref.watch(gachaSyncProvider);
  return ref.watch(gachaRepositoryProvider).linkExpiresAt(game);
}

@freezed
abstract class GachaSyncState with _$GachaSyncState {
  const factory GachaSyncState({
    Game? syncing,
    @Default(0) int fetched,
    @Default(<Game, DateTime>{}) Map<Game, DateTime> lastSynced,
  }) = _GachaSyncState;
}

@Riverpod(keepAlive: true)
class GachaSync extends _$GachaSync {
  @override
  GachaSyncState build() => const GachaSyncState();

  Future<Game> importLink(String raw) async {
    final game = await ref.read(gachaRepositoryProvider).importLink(raw);
    await sync(game);
    return game;
  }

  Future<void> sync(Game game) async {
    if (state.syncing != null) return;
    state = state.copyWith(syncing: game, fetched: 0);
    try {
      await ref
          .read(gachaRepositoryProvider)
          .sync(
            game,
            onProgress: (fetched) => state = state.copyWith(fetched: fetched),
          );
      state = state.copyWith(
        lastSynced: {...state.lastSynced, game: ref.read(clockProvider)()},
      );
    } finally {
      state = state.copyWith(syncing: null);
    }
  }
}
