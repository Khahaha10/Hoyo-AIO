import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';

enum GameRegion {
  asia,
  america,
  europe,
  twHkMo;

  String? serverIdFor(Game game) => HoyolabConfig.serverIds[game]?[this];
}

GameRegion? regionFromServerId(Game game, String serverId) {
  final ids = HoyolabConfig.serverIds[game];
  if (ids == null) return null;
  for (final MapEntry(key: region, value: id) in ids.entries) {
    if (id == serverId) return region;
  }
  return null;
}
