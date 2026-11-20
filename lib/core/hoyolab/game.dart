import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';

enum Game {
  genshin,
  starRail,
  zzz,
  hi3;

  int get hoyolabGameId => HoyolabConfig.gameIds[this] ?? 0;
}

Game? gameFromHoyolabId(int id) {
  for (final MapEntry(key: game, value: gameId)
      in HoyolabConfig.gameIds.entries) {
    if (gameId == id) return game;
  }
  return null;
}
