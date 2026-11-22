import 'package:dio/dio.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/databook/data/json_view.dart';

class WarpStatsRemoteSource {
  WarpStatsRemoteSource(this._dio);

  static const _endpointFiveStars = 'five_star_list';
  static const _endpointPools = 'pool_stat';
  static const _maxPages = 20;

  final Dio _dio;
  final _tokens = <String, String>{};

  Future<List<Json>> fiveStarRows(SavedRole role, String gachaType) async {
    final rows = <Json>[];
    var params = {'gacha_type': gachaType};
    for (var page = 0; page < _maxPages; page++) {
      final data = await _get(role, _endpointFiveStars, params);
      rows.addAll(data['list'].items);
      if (!data['has_more'].boolValue) break;
      params = {
        'gacha_type': gachaType,
        'version_id': data['version_id'].stringValue,
        'max_id': data['next_max_id'].stringValue,
      };
    }
    return rows;
  }

  Future<List<Json>> pools(SavedRole role, String gachaType) async {
    final data = await _get(role, _endpointPools, {'gacha_type': gachaType});
    return data['cards'].items;
  }

  Future<Json> _get(
    SavedRole role,
    String endpoint,
    Map<String, String> params,
  ) async {
    final token = _tokens[role.accountId] ?? await _login(role);
    try {
      return await _request(role, endpoint, params, token);
    } on CookieExpiredException {
      return _request(role, endpoint, params, await _login(role));
    }
  }

  Future<Json> _request(
    SavedRole role,
    String endpoint,
    Map<String, String> params,
    String token,
  ) async {
    final response = await guardHoyolab(
      () => _dio.getUri<Map<String, dynamic>>(
        Uri.https(
          HoyolabConfig.warpHost,
          '${HoyolabConfig.warpRecordsPath}/$endpoint',
          {..._baseParams(role), ...params},
        ),
        options: _options(role, token),
      ),
    );
    return Json(response.data?['data']);
  }

  Future<String> _login(SavedRole role) async {
    _tokens.remove(role.accountId);
    final response = await guardHoyolab(
      () => _dio.postUri<Map<String, dynamic>>(
        Uri.https(HoyolabConfig.warpHost, HoyolabConfig.badgeLoginPath),
        data: {
          'game_biz': HoyolabConfig.warpGameBiz,
          'lang': HoyolabConfig.languageEnglish,
          'region': role.server,
          'uid': role.uid,
        },
        options: _options(role, null),
      ),
    );
    final token = _tokenFrom(response.headers['set-cookie'] ?? const []);
    if (token.isEmpty) throw const ParseException('warp: no badge token');
    _tokens[role.accountId] = token;
    return token;
  }

  static String _tokenFrom(List<String> setCookies) {
    final pairs = <String>[];
    for (final line in setCookies) {
      final pair = line.split(';').first.trim();
      final name = pair.split('=').first;
      if (HoyolabConfig.warpTokenCookies.contains(name)) pairs.add(pair);
    }
    return pairs.join('; ');
  }

  static Map<String, String> _baseParams(SavedRole role) => {
    'game_biz': HoyolabConfig.warpGameBiz,
    'region': role.server,
    'uid': role.uid,
  };

  static Options _options(SavedRole role, String? token) => hoyolabOptions(
    accountId: role.accountId,
    profile: HeaderProfile.warpRecords,
    extraCookie: token,
    keepAccountOnExpired: true,
  );
}
