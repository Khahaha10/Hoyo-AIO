import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';

class GachaLink {
  const GachaLink({
    required this.game,
    required this.params,
    required this.expiresAt,
  });

  final Game game;
  final Map<String, String> params;
  final DateTime expiresAt;

  bool isValidAt(DateTime now) => now.isBefore(expiresAt);

  static GachaLink? parse(String raw, DateTime now) {
    final match = RegExp(r'https://\S+').firstMatch(raw.trim());
    final uri = match == null ? null : Uri.tryParse(match.group(0) ?? '');
    if (uri == null || !uri.host.endsWith(HoyolabConfig.gachaLinkHostSuffix)) {
      return null;
    }
    final query = {...uri.queryParameters};
    final fragment = Uri.tryParse(
      uri.fragment.contains('?')
          ? uri.fragment.substring(uri.fragment.indexOf('?'))
          : '',
    );
    query.addAll(fragment?.queryParameters ?? const {});
    final authkey = query['authkey'];
    if (authkey == null || authkey.isEmpty) return null;
    final game = _game(uri, query);
    if (game == null) return null;
    return GachaLink(
      game: game,
      params: {
        for (final key in HoyolabConfig.gachaKeptParams)
          if (query[key] case final value? when value.isNotEmpty) key: value,
      },
      expiresAt: now.add(HoyolabConfig.gachaAuthkeyLifetime),
    );
  }

  static Game? _game(Uri uri, Map<String, String> query) {
    final biz = HoyolabConfig.gachaGameBizToGame[query['game_biz']];
    if (biz != null) return biz;
    final path = uri.path.toLowerCase();
    for (final MapEntry(:key, :value)
        in HoyolabConfig.gachaPathMarkers.entries) {
      if (path.contains('/$key/')) return value;
    }
    return null;
  }
}
