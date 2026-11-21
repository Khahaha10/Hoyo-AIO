import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';

const trackerGames = [Game.genshin, Game.starRail, Game.zzz];

extension TrackerLabels on AppLocalizations {
  String trackerChip(Game game) => switch (game) {
    Game.starRail => trackerWarps,
    Game.zzz => trackerSignals,
    _ => trackerWishes,
  };

  String trackerTitle(Game game) => switch (game) {
    Game.starRail => trackerWarpTitle,
    Game.zzz => trackerSignalTitle,
    _ => trackerWishTitle,
  };

  String trackerHistoryTitle(Game game) => switch (game) {
    Game.starRail => trackerWarpHistory,
    Game.zzz => trackerSignalHistory,
    _ => trackerWishHistory,
  };

  String trackerPulls(Game game, int count) => switch (game) {
    Game.starRail => trackerWarpCount(count),
    Game.zzz => trackerSignalCount(count),
    _ => trackerWishCount(count),
  };

  String trackerCurrency(Game game) => switch (game) {
    Game.starRail => trackerStellarJade,
    Game.zzz => trackerPolychrome,
    _ => trackerPrimogem,
  };

  String trackerBanner(Game game, String banner) =>
      switch ('${game.name}.$banner') {
        'genshin.301' || 'starRail.11' => trackerBannerCharacter,
        'genshin.302' => trackerBannerWeapon,
        'starRail.12' => trackerBannerLightCone,
        'zzz.2' => trackerBannerAgent,
        'zzz.3' => trackerBannerWEngine,
        'genshin.500' => trackerBannerChronicled,
        'zzz.5' => trackerBannerBangboo,
        'genshin.100' || 'starRail.2' => trackerBannerBeginner,
        _ => trackerBannerStandard,
      };
}
