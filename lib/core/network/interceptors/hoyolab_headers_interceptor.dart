import 'package:dio/dio.dart';
import 'package:hoyo_aio/core/hoyolab/dynamic_secret.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';

class HoyolabHeadersInterceptor extends Interceptor {
  HoyolabHeadersInterceptor({
    required DynamicSecret dynamicSecret,
    required this.language,
    DateTime Function()? now,
  }) : _ds = dynamicSecret,
       _now = now ?? DateTime.now;

  final DynamicSecret _ds;
  final String Function() language;
  final DateTime Function() _now;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final headers = switch (options.hoyolabProfile) {
      HeaderProfile.gameRecord => _gameRecordHeaders(),
      HeaderProfile.zzzNotes => _zzzNotesHeaders(),
      HeaderProfile.checkIn => _checkInHeaders(options),
      HeaderProfile.community => _communityHeaders(),
      null => const <String, String>{},
    };
    options.headers.addAll(headers);
    handler.next(options);
  }

  Map<String, String> _gameRecordHeaders() => {
    'Accept': 'application/json, text/plain, */*',
    'Content-Type': 'application/json;charset=UTF-8',
    'Referer': HoyolabConfig.gameRecordReferer,
    'x-rpc-client_type': HoyolabConfig.clientTypeGameRecord,
    'x-rpc-app_version': HoyolabConfig.appVersion,
    'x-rpc-language': language(),
    'DS': _ds.generate(),
  };

  Map<String, String> _communityHeaders() => {
    'Accept': 'application/json, text/plain, */*',
    'Origin': HoyolabConfig.hoyolabWebUrl,
    'Referer': HoyolabConfig.hoyolabHomeUrl,
    'x-rpc-client_type': HoyolabConfig.clientTypeGameRecord,
    'x-rpc-language': language(),
  };

  Map<String, String> _zzzNotesHeaders() => {
    'Accept': '*/*',
    'Content-Type': 'application/json',
    'Origin': HoyolabConfig.actOrigin,
    'Referer': HoyolabConfig.actReferer,
    'x-rpc-client_type': HoyolabConfig.clientTypeGameRecord,
    'x-rpc-app_version': HoyolabConfig.appVersion,
    'x-rpc-language': language(),
  };

  Map<String, String> _checkInHeaders(RequestOptions options) {
    final game = options.hoyolabGame;
    final endpoint = game == null ? null : HoyolabConfig.checkIn[game];
    if (endpoint == null) return const {};
    return {
      'Accept': 'application/json, text/plain, */*',
      'Content-Type': 'application/json;charset=UTF-8',
      ...endpoint.headers,
      if (endpoint.signGame != null) 'x-rpc-signgame': endpoint.signGame!,
      if (endpoint.sendsTimestamp)
        'Timestamp': '${_now().millisecondsSinceEpoch ~/ 1000}',
    };
  }
}
