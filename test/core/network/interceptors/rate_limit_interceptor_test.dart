import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';
import 'package:hoyo_aio/core/network/interceptors/rate_limit_interceptor.dart';

class _Capture extends RequestInterceptorHandler {
  var passed = 0;

  @override
  void next(RequestOptions requestOptions) => passed++;
}

RequestOptions _request(String account, String path) => RequestOptions(
  path: 'https://${HoyolabConfig.gameRecordHost}$path',
  extra: hoyolabOptions(
    accountId: account,
    profile: HeaderProfile.gameRecord,
  ).extra,
);

void main() {
  group('RateLimitInterceptor', () {
    late DateTime now;
    late List<Duration> waits;
    late RateLimitInterceptor limiter;
    late _Capture handler;

    setUp(() {
      now = DateTime.utc(2026, 11, 21, 12);
      waits = [];
      limiter = RateLimitInterceptor(
        minInterval: const Duration(seconds: 2),
        now: () => now,
        wait: (d) async => waits.add(d),
      );
      handler = _Capture();
    });

    test('first call passes without waiting', () async {
      await limiter.onRequest(_request('a', '/x'), handler);

      expect(handler.passed, 1);
      expect(waits, isEmpty);
    });

    test('a second call to the same account and path waits', () async {
      await limiter.onRequest(_request('a', '/x'), handler);
      now = now.add(const Duration(milliseconds: 500));

      await limiter.onRequest(_request('a', '/x'), handler);

      expect(handler.passed, 2);
      expect(waits, const [Duration(milliseconds: 1500)]);
    });

    test('back-to-back calls queue up behind each other', () async {
      await limiter.onRequest(_request('a', '/x'), handler);
      await limiter.onRequest(_request('a', '/x'), handler);
      await limiter.onRequest(_request('a', '/x'), handler);

      expect(waits, const [Duration(seconds: 2), Duration(seconds: 4)]);
    });

    test('other accounts and paths are independent', () async {
      await limiter.onRequest(_request('a', '/x'), handler);
      await limiter.onRequest(_request('b', '/x'), handler);
      await limiter.onRequest(_request('a', '/y'), handler);

      expect(waits, isEmpty);
    });

    test('after the interval has passed there is no wait', () async {
      await limiter.onRequest(_request('a', '/x'), handler);
      now = now.add(const Duration(seconds: 3));

      await limiter.onRequest(_request('a', '/x'), handler);

      expect(waits, isEmpty);
    });
  });
}
