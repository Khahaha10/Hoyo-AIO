import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/hoyolab/dynamic_secret.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';
import 'package:hoyo_aio/core/network/interceptors/hoyolab_headers_interceptor.dart';

class _Capture extends RequestInterceptorHandler {
  RequestOptions? passed;

  @override
  void next(RequestOptions requestOptions) => passed = requestOptions;
}

Map<String, dynamic> _headers(Options options) {
  final interceptor = HoyolabHeadersInterceptor(
    dynamicSecret: DynamicSecret(
      now: () => DateTime.fromMillisecondsSinceEpoch(1700000000000),
      random: Random(3),
    ),
    language: () => HoyolabConfig.languageIndonesian,
    now: () => DateTime.fromMillisecondsSinceEpoch(1700000000500),
  );
  final request = RequestOptions(
    path: 'https://${HoyolabConfig.gameRecordHost}/x',
    extra: options.extra,
  );
  final handler = _Capture();
  interceptor.onRequest(request, handler);
  return handler.passed!.headers;
}

void main() {
  group('HoyolabHeadersInterceptor', () {
    test('game record profile adds a DS for the injected clock', () {
      final headers = _headers(
        hoyolabOptions(accountId: '1', profile: HeaderProfile.gameRecord),
      );

      expect(headers['DS'], startsWith('1700000000,'));
      expect(headers['x-rpc-language'], HoyolabConfig.languageIndonesian);
      expect(headers['Referer'], HoyolabConfig.gameRecordReferer);
    });

    test('zzz notes profile uses act origin and no DS', () {
      final headers = _headers(
        hoyolabOptions(accountId: '1', profile: HeaderProfile.zzzNotes),
      );

      expect(headers['Origin'], HoyolabConfig.actOrigin);
      expect(headers.containsKey('DS'), isFalse);
    });

    test('community profile sends web origin and no DS', () {
      final headers = _headers(communityOptions());

      expect(headers['Origin'], HoyolabConfig.hoyolabWebUrl);
      expect(headers['Referer'], HoyolabConfig.hoyolabHomeUrl);
      expect(headers.containsKey('DS'), isFalse);
    });

    test('check-in for ZZZ adds signgame and a timestamp in seconds', () {
      final headers = _headers(
        hoyolabOptions(
          accountId: '1',
          profile: HeaderProfile.checkIn,
          game: Game.zzz,
        ),
      );

      expect(headers['x-rpc-signgame'], 'zzz');
      expect(headers['Timestamp'], '1700000000');
      expect(headers['Origin'], HoyolabConfig.actOrigin);
    });

    test('check-in for Genshin has no signgame or timestamp', () {
      final headers = _headers(
        hoyolabOptions(
          accountId: '1',
          profile: HeaderProfile.checkIn,
          game: Game.genshin,
        ),
      );

      expect(headers.containsKey('x-rpc-signgame'), isFalse);
      expect(headers.containsKey('Timestamp'), isFalse);
      expect(headers['User-Agent'], HoyolabConfig.mobileChromeUserAgent);
    });

    test(
      'check-in without a game and requests without a profile add nothing',
      () {
        final checkIn = _headers(
          hoyolabOptions(accountId: '1', profile: HeaderProfile.checkIn),
        );
        final plain = _headers(Options());

        expect(checkIn.containsKey('Accept'), isFalse);
        expect(plain.containsKey('Accept'), isFalse);
      },
    );
  });
}
