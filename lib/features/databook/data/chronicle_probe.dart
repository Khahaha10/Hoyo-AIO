import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';

class ChronicleProbe {
  const ChronicleProbe(this._dio);

  static const fileName = 'chronicle_probe.json';
  static const _sampleItems = 2;
  static const _maskedKeys = {
    'nickname',
    'nick_name',
    'uid',
    'role_id',
    'game_uid',
    'game_role_id',
    'account_id',
    'hoyolab_id',
    'signature',
    'introduce',
  };

  final Dio _dio;

  static File get outputFile => File('${Directory.systemTemp.path}/$fileName');

  Future<Map<String, Object?>> run(List<SavedRole> roles) async {
    final results = <String, Object?>{};
    for (final game in const [Game.genshin, Game.starRail, Game.zzz]) {
      final role = roles.where((r) => r.game == game).firstOrNull;
      if (role != null) results[game.name] = await _probeRole(role);
    }
    await outputFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(results),
    );
    return results;
  }

  Future<Map<String, Object?>> _probeRole(SavedRole role) async {
    final results = <String, Object?>{};
    String? firstId;
    for (final endpoint in HoyolabConfig.chronicleEndpoints) {
      if (endpoint.game != role.game) continue;
      if (endpoint.idParam != null && firstId == null) continue;
      final outcome = await _call(role, endpoint, entityId: firstId);
      results[endpoint.key] = outcome.summary;
      if (endpoint.key == 'zzz.agents' || endpoint.key == 'gi.characters') {
        firstId = _firstEntityId(outcome.raw);
      }
    }
    return results;
  }

  Future<({Map<String, Object?> summary, Object? raw})> _call(
    SavedRole role,
    ChronicleEndpoint endpoint, {
    String? entityId,
  }) async {
    try {
      final response = await guardHoyolab(
        () => _request(role, endpoint, entityId),
      );
      final body = response.data;
      final data = body?['data'];
      final lengths = <String, int>{};
      return (
        summary: {
          'retcode': body?['retcode'],
          'data': _sanitize(data, lengths, ''),
          'listLengths': lengths,
        },
        raw: data,
      );
    } on AppException catch (e) {
      return (summary: {'error': _describe(e)}, raw: null);
    }
  }

  Future<Response<Map<String, dynamic>>> _request(
    SavedRole role,
    ChronicleEndpoint endpoint,
    String? entityId,
  ) {
    final host = role.game == Game.zzz
        ? HoyolabConfig.zzzRecordHost
        : HoyolabConfig.gameRecordHost;
    final profile = role.game == Game.zzz
        ? HeaderProfile.zzzNotes
        : HeaderProfile.gameRecord;
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
          endpoint.idParam != null &&
          entityId != null)
        endpoint.idParam!: entityId,
    };
    final options = hoyolabOptions(
      accountId: role.accountId,
      profile: profile,
      game: role.game,
    );
    return switch (endpoint.method) {
      ChronicleMethod.get => _dio.getUri<Map<String, dynamic>>(
        Uri.https(host, endpoint.path, query),
        options: options,
      ),
      ChronicleMethod.post => _dio.postUri<Map<String, dynamic>>(
        Uri.https(host, endpoint.path),
        data: {
          ...query,
          if (endpoint.idParam case final param? when entityId != null)
            param: [int.tryParse(entityId) ?? entityId],
        },
        options: options,
      ),
    };
  }

  static String? _firstEntityId(Object? data) {
    final list = data is Map ? (data['avatar_list'] ?? data['list']) : null;
    final first = list is List && list.isNotEmpty ? list.first : null;
    final id = first is Map ? first['id'] : null;
    return id?.toString();
  }

  static Object? _sanitize(
    Object? node,
    Map<String, int> lengths,
    String path,
  ) {
    if (node is Map) {
      return {
        for (final MapEntry(:key, :value) in node.entries)
          '$key': _maskedKeys.contains('$key'.toLowerCase())
              ? '***'
              : _sanitize(value, lengths, path.isEmpty ? '$key' : '$path.$key'),
      };
    }
    if (node is List) {
      lengths[path.isEmpty ? '(root)' : path] = node.length;
      return [
        for (final item in node.take(_sampleItems))
          _sanitize(item, lengths, '$path[]'),
      ];
    }
    return node;
  }

  static String _describe(AppException e) => switch (e) {
    ServerException(:final retcode, :final message) =>
      'server $retcode $message',
    CookieExpiredException(:final retcode) => 'cookie expired ($retcode)',
    NoRolesException(:final retcode) => 'no roles ($retcode)',
    RateLimitedException(:final retryable) =>
      'rate limited (retryable $retryable)',
    _ => e.runtimeType.toString(),
  };
}
