import 'package:dio/dio.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/databook/data/json_view.dart';

class ChronicleRemoteSource {
  const ChronicleRemoteSource(this._dio);

  static const _chronicleSwitchName = 'battle chronicle';

  final Dio _dio;

  static ChronicleEndpoint endpoint(String key) =>
      HoyolabConfig.chronicleEndpoints.firstWhere((e) => e.key == key);

  Future<Json> fetch(SavedRole role, String key, {String? entityId}) async {
    final body = await fetchBody(role, endpoint(key), entityId: entityId);
    return Json(body['data']);
  }

  Future<Map<String, dynamic>> fetchBody(
    SavedRole role,
    ChronicleEndpoint endpoint, {
    String? entityId,
  }) async {
    final response = await guardHoyolab(
      () => _request(role, endpoint, entityId),
    );
    final body = response.data;
    if (body == null) throw const ParseException('chronicle: empty body');
    return body;
  }

  Future<void> makePublic(SavedRole role) async {
    final card = await guardHoyolab(
      () => _dio.getUri<Map<String, dynamic>>(
        Uri.https(HoyolabConfig.gameRecordHost, HoyolabConfig.recordCardPath, {
          'uid': role.accountId,
        }),
        options: hoyolabOptions(
          accountId: role.accountId,
          profile: HeaderProfile.gameRecord,
        ),
      ),
    );
    final mine = Json(card.data?['data'])['list'].items
        .where(
          (c) =>
              c['game_id'].intOrNull == role.game.hoyolabGameId &&
              c['game_role_id'].stringOrNull == role.uid,
        )
        .firstOrNull;
    final chronicleSwitch = (mine ?? const Json(null))['data_switches'].items
        .where(
          (s) => s['switch_name'].stringValue.toLowerCase().contains(
            _chronicleSwitchName,
          ),
        )
        .firstOrNull;
    final switchId =
        chronicleSwitch?['switch_id'].intOrNull ??
        HoyolabConfig.chronicleSwitchId;
    await guardHoyolab(
      () => _dio.postUri<Map<String, dynamic>>(
        Uri.https(
          HoyolabConfig.gameRecordHost,
          HoyolabConfig.changeDataSwitchPath,
          {
            'game_id': '${role.game.hoyolabGameId}',
            'switch_id': '$switchId',
            'is_public': 'true',
          },
        ),
        options: hoyolabOptions(
          accountId: role.accountId,
          profile: HeaderProfile.gameRecord,
        ),
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> _request(
    SavedRole role,
    ChronicleEndpoint endpoint,
    String? entityId,
  ) {
    final isZzz = role.game == Game.zzz;
    final host = isZzz
        ? HoyolabConfig.zzzRecordHost
        : HoyolabConfig.gameRecordHost;
    final options = hoyolabOptions(
      accountId: role.accountId,
      profile: isZzz ? HeaderProfile.zzzNotes : HeaderProfile.gameRecord,
      game: role.game,
    );
    final idParam = endpoint.idParam;
    final query = <String, String>{
      if (endpoint.uidRegionParams) ...{
        'uid': role.uid,
        'region': role.server,
      } else ...{
        'role_id': role.uid,
        'server': role.server,
      },
      ...endpoint.params,
      if (endpoint.method == ChronicleMethod.get &&
          idParam != null &&
          entityId != null)
        idParam: entityId,
    };
    return switch (endpoint.method) {
      ChronicleMethod.get => _dio.getUri<Map<String, dynamic>>(
        Uri.https(host, endpoint.path, query),
        options: options,
      ),
      ChronicleMethod.post => _dio.postUri<Map<String, dynamic>>(
        Uri.https(host, endpoint.path),
        data: {
          ...query,
          if (idParam != null && entityId != null)
            idParam: [int.tryParse(entityId) ?? entityId],
        },
        options: options,
      ),
    };
  }
}
