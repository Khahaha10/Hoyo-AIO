import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/game_region.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';

extension GameLabels on AppLocalizations {
  String gameName(Game game) => switch (game) {
    Game.genshin => gameGenshin,
    Game.starRail => gameStarRail,
    Game.zzz => gameZzz,
    Game.hi3 => gameHi3,
  };

  String gameShortName(Game game) => switch (game) {
    Game.genshin => gameShortGenshin,
    Game.starRail => gameShortStarRail,
    Game.zzz => gameShortZzz,
    Game.hi3 => gameShortHi3,
  };

  String gameLevel(Game game, int level) => switch (game) {
    Game.genshin => levelGenshin(level),
    Game.starRail => levelStarRail(level),
    Game.zzz => levelZzz(level),
    Game.hi3 => levelHi3(level),
  };

  String regionName(GameRegion region) => switch (region) {
    GameRegion.asia => regionAsia,
    GameRegion.america => regionAmerica,
    GameRegion.europe => regionEurope,
    GameRegion.twHkMo => regionTwHkMo,
  };
}

String groupUid(String uid) {
  const group = 3;
  if (uid.length <= group * 2) return uid;
  final tail = uid.length - group;
  final middle = tail - group;
  return '${uid.substring(0, middle)} '
      '${uid.substring(middle, tail)} '
      '${uid.substring(tail)}';
}
