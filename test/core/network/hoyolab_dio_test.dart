import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/dynamic_secret.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';

import '_support/fake_adapter.dart';

const _cookie = 'ltuid_v2=800000001; ltoken_v2=fake';

class _Harness {
  _Harness(FakeAdapter adapter, {String? cookie = _cookie})
    : this._(adapter, cookie, <String>[], <String>[], <String>[]);

  _Harness._(
    this.adapter,
    String? cookie,
    this.cookieReads,
    this.logs,
    this.expired,
  ) : dio = buildHoyolabDio(
        cookies: (accountId) async {
          cookieReads.add(accountId);
          return cookie;
        },
        log: (message, {isError = false}) => logs.add(message),
        verboseLogging: true,
        onCookieExpired: expired.add,
        dynamicSecret: DynamicSecret(
          now: () => DateTime.utc(2026, 11, 21),
          random: Random(1),
        ),
        adapter: adapter,
      );

  final FakeAdapter adapter;
  final List<String> cookieReads;
  final List<String> logs;
  final List<String> expired;
  final Dio dio;
}

Uri _recordUri([String path = HoyolabConfig.recordCardPath]) =>
    Uri.https(HoyolabConfig.gameRecordHost, path, {'uid': '800000001'});

Future<AppException> _failure(Future<Object?> request) async {
  try {
    await guardHoyolab(() => request);
  } on AppException catch (e) {
    return e;
  }
  fail('request did not fail');
}

void main() {
  group('buildHoyolabDio host allowlist', () {
    test('rejects a foreign host before the cookie vault is read', () async {
      final h = _Harness(FakeAdapter.json({'retcode': 0}));

      final error = await _failure(
        h.dio.getUri<Object?>(
          Uri.https('evil.example.com', '/steal'),
          options: hoyolabOptions(
            accountId: '800000001',
            profile: HeaderProfile.gameRecord,
          ),
        ),
      );

      expect(error, isA<ForbiddenHostException>());
      expect((error as ForbiddenHostException).host, 'evil.example.com');
      expect(h.cookieReads, isEmpty);
      expect(h.adapter.requests, isEmpty);
    });

    test('rejects plain http to an allowed host', () async {
      final h = _Harness(FakeAdapter.json({'retcode': 0}));

      final error = await _failure(
        h.dio.getUri<Object?>(
          Uri.http(HoyolabConfig.gameRecordHost, '/x'),
          options: hoyolabOptions(
            accountId: '800000001',
            profile: HeaderProfile.gameRecord,
          ),
        ),
      );

      expect(error, isA<ForbiddenHostException>());
      expect(h.cookieReads, isEmpty);
    });
  });

  group('buildHoyolabDio success path', () {
    test('sends cookie, DS and game record headers to an allowed host', () async {
      final h = _Harness(FakeAdapter.json({'retcode': 0, 'data': {}}));

      final response = await h.dio.getUri<Map<String, dynamic>>(
        _recordUri(),
        options: hoyolabOptions(
          accountId: '800000001',
          profile: HeaderProfile.gameRecord,
        ),
      );

      final sent = h.adapter.requests.single.headers;
      expect(response.data?['retcode'], 0);
      expect(h.cookieReads, ['800000001']);
      expect(sent['Cookie'], _cookie);
      expect(sent['DS'], matches(RegExp(r'^\d+,[a-z]{6},[0-9a-f]{32}$')));
      expect(sent['x-rpc-client_type'], HoyolabConfig.clientTypeGameRecord);
      expect(sent['x-rpc-app_version'], HoyolabConfig.appVersion);
      expect(sent['x-rpc-language'], HoyolabConfig.languageEnglish);
      expect(sent['Referer'], HoyolabConfig.gameRecordReferer);
    });

    test('never sends the cookie to a gacha host', () async {
      final h = _Harness(FakeAdapter.json({'retcode': 0}));

      await h.dio.getUri<Object?>(
        Uri.https(HoyolabConfig.gachaHosts[Game.genshin]!, '/log'),
        options: hoyolabOptions(
          accountId: '800000001',
          profile: HeaderProfile.community,
        ),
      );

      expect(h.cookieReads, isEmpty);
      expect(h.adapter.requests.single.headers.containsKey('Cookie'), isFalse);
    });

    test('verbose log lines never contain the cookie', () async {
      final h = _Harness(FakeAdapter.json({'retcode': 0}));

      await h.dio.getUri<Object?>(
        _recordUri(),
        options: hoyolabOptions(
          accountId: '800000001',
          profile: HeaderProfile.gameRecord,
        ),
      );

      expect(h.logs, hasLength(2));
      for (final line in h.logs) {
        expect(line, isNot(contains('fake')));
        expect(line, isNot(contains('800000001')));
      }
    });
  });

  group('buildHoyolabDio retcodes', () {
    test('maps an expired-cookie retcode and reports the account', () async {
      final h = _Harness(FakeAdapter.json({'retcode': -100, 'message': 'x'}));

      final error = await _failure(
        h.dio.getUri<Object?>(
          _recordUri(),
          options: hoyolabOptions(
            accountId: '800000001',
            profile: HeaderProfile.gameRecord,
          ),
        ),
      );

      expect(error, isA<CookieExpiredException>());
      expect(h.expired, ['800000001']);
    });

    test('a missing vault cookie fails as expired without a request', () async {
      final h = _Harness(FakeAdapter.json({'retcode': 0}), cookie: null);

      final error = await _failure(
        h.dio.getUri<Object?>(
          _recordUri(),
          options: hoyolabOptions(
            accountId: '800000001',
            profile: HeaderProfile.gameRecord,
          ),
        ),
      );

      expect(error, isA<CookieExpiredException>());
      expect(h.adapter.requests, isEmpty);
    });

    test('a body without retcode is a parse error', () async {
      final h = _Harness(FakeAdapter.json({'data': 1}));

      final error = await _failure(h.dio.getUri<Object?>(_recordUri()));

      expect(error, isA<ParseException>());
    });

    test('retries a network error once and then succeeds', () async {
      var calls = 0;
      final h = _Harness(
        FakeAdapter((_) {
          calls++;
          if (calls == 1) return const SocketException('down');
          return {'retcode': 0};
        }),
      );

      final response = await h.dio.getUri<Map<String, dynamic>>(
        _recordUri('/retry'),
      );

      expect(response.data?['retcode'], 0);
      expect(h.adapter.requests, hasLength(2));
    });
  });

  group('guardHoyolab', () {
    test('turns FormatException and TypeError into ParseException', () async {
      expect(
        await _failure(Future<Object?>.error(const FormatException('bad'))),
        isA<ParseException>(),
      );
      expect(
        await _failure(Future<Object?>(() => (1 as dynamic) as String)),
        isA<ParseException>(),
      );
    });

    test('passes AppException through unchanged', () async {
      expect(
        await _failure(Future<Object?>.error(const CaptchaRequiredException())),
        isA<CaptchaRequiredException>(),
      );
    });
  });
}
