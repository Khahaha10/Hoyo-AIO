import 'dart:convert';
import 'dart:io';

import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/databook/data/chronicle_remote_source.dart';

class ChronicleProbe {
  const ChronicleProbe(this._remote);

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

  final ChronicleRemoteSource _remote;

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
      final body = await _remote.fetchBody(role, endpoint, entityId: entityId);
      final data = body['data'];
      final lengths = <String, int>{};
      return (
        summary: {
          'retcode': body['retcode'],
          'data': _sanitize(data, lengths, ''),
          'listLengths': lengths,
        },
        raw: data,
      );
    } on AppException catch (e) {
      return (summary: {'error': _describe(e)}, raw: null);
    }
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
