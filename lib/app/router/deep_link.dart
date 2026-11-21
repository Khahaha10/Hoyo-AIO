import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';

abstract final class DeepLink {
  static const scheme = 'hoyoaio';
  static const dashboardHost = 'dashboard';

  static const _dashboardGames = {Game.genshin, Game.starRail, Game.zzz};
  static final _roleId = RegExp(r'^\d{1,12}$');

  static bool isDeepLink(Uri uri) => uri.scheme == scheme;

  static String toLocation(Uri uri) {
    if (!isDeepLink(uri) || uri.host != dashboardHost) {
      return AppRoutes.dashboard;
    }
    final game = Game.values
        .where((g) => g.name == uri.queryParameters[AppRoutes.gameParam])
        .where(_dashboardGames.contains)
        .firstOrNull;
    final role = uri.queryParameters[AppRoutes.roleParam];
    return Uri(
      path: AppRoutes.dashboard,
      queryParameters: {
        AppRoutes.gameParam: ?game?.name,
        if (role != null && _roleId.hasMatch(role)) AppRoutes.roleParam: role,
      },
    ).toString().replaceFirst(RegExp(r'\?$'), '');
  }
}
