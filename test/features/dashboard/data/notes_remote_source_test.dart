import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/features/dashboard/data/notes_remote_source.dart';

import '../_support/dashboard_fakes.dart';
import '../_support/json_adapter.dart';

void main() {
  (NotesRemoteSource, JsonAdapter) build(
    Object Function(RequestOptions) reply,
  ) {
    final adapter = JsonAdapter(reply);
    final dio = Dio()..httpClientAdapter = adapter;
    return (NotesRemoteSource(dio), adapter);
  }

  final cases = <(Game, String, String)>[
    (Game.genshin, HoyolabConfig.gameRecordHost, HoyolabConfig.genshinNotePath),
    (
      Game.starRail,
      HoyolabConfig.gameRecordHost,
      HoyolabConfig.starRailNotePath,
    ),
    (Game.zzz, HoyolabConfig.zzzRecordHost, HoyolabConfig.zzzNotePath),
  ];
  for (final (game, host, path) in cases) {
    test('${game.name} requests the notes endpoint and returns data', () async {
      final (source, adapter) = build(
        (_) => {
          'retcode': 0,
          'data': {'current_resin': 1},
        },
      );
      final role = fakeRole(game);

      final data = await source.fetch(role);

      expect(data, {'current_resin': 1});
      final uri = adapter.requests.single.uri;
      expect(uri.host, host);
      expect(uri.path, path);
      expect(uri.queryParameters, {'role_id': role.uid, 'server': 'os_asia'});
    });
  }

  test('throws ParseException when data is missing', () async {
    final (source, _) = build((_) => {'retcode': 0, 'data': null});

    await expectLater(
      source.fetch(fakeRole(Game.genshin)),
      throwsA(isA<ParseException>()),
    );
  });

  test('maps a connection failure to NetworkException', () async {
    final (source, _) = build(
      (options) => DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: const SocketException('offline'),
      ),
    );

    await expectLater(
      source.fetch(fakeRole(Game.zzz)),
      throwsA(isA<NetworkException>()),
    );
  });

  test('rejects HI3 before any request', () async {
    final (source, adapter) = build((_) => const <String, Object>{});

    expect(() => source.fetch(fakeRole(Game.hi3)), throwsArgumentError);
    expect(adapter.requests, isEmpty);
  });
}
