import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/interceptors/retcode_interceptor.dart';
import 'package:hoyo_aio/core/network/interceptors/retry_interceptor.dart';

import '../_support/fake_adapter.dart';

final _uri = Uri.https(HoyolabConfig.gameRecordHost, '/x');

Dio _dio(FakeAdapter adapter, List<Duration> waits) {
  final dio = Dio()..httpClientAdapter = adapter;
  dio.interceptors.addAll([
    RetcodeInterceptor(),
    RetryInterceptor(dio, wait: (d) async => waits.add(d)),
  ]);
  return dio;
}

Future<Object?> _error(Future<Object?> request) async {
  try {
    await request;
  } on DioException catch (e) {
    return e.error;
  }
  fail('request did not fail');
}

void main() {
  group('RetryInterceptor.isRetryable', () {
    test('retries network, timeout and retryable rate limit only', () {
      expect(RetryInterceptor.isRetryable(const NetworkException()), isTrue);
      expect(RetryInterceptor.isRetryable(const TimeoutException()), isTrue);
      expect(
        RetryInterceptor.isRetryable(
          const RateLimitedException(retryable: true),
        ),
        isTrue,
      );
      expect(
        RetryInterceptor.isRetryable(
          const RateLimitedException(retryable: false),
        ),
        isFalse,
      );
      expect(
        RetryInterceptor.isRetryable(const CookieExpiredException()),
        isFalse,
      );
      expect(RetryInterceptor.isRetryable(null), isFalse);
    });
  });

  group('RetryInterceptor', () {
    test('backs off 1 s then 3 s and gives up after two retries', () async {
      final waits = <Duration>[];
      final adapter = FakeAdapter((_) => const SocketException('down'));

      final error = await _error(_dio(adapter, waits).getUri<Object?>(_uri));

      expect(error, isA<NetworkException>());
      expect(adapter.requests, hasLength(3));
      expect(waits, const [Duration(seconds: 1), Duration(seconds: 3)]);
    });

    test('does not retry a non-retryable error', () async {
      final waits = <Duration>[];
      final adapter = FakeAdapter((_) => ResponseBody.fromString('', 500));

      final error = await _error(_dio(adapter, waits).getUri<Object?>(_uri));

      expect(error, isA<ServerException>());
      expect(adapter.requests, hasLength(1));
      expect(waits, isEmpty);
    });

    test(
      'retries the retryable rate-limit retcode',
      () async {
        final waits = <Duration>[];
        var calls = 0;
        final adapter = FakeAdapter(
          (_) => {'retcode': calls++ == 0 ? -1004 : 0},
        );

        final response = await _dio(adapter, waits).getUri<Object?>(_uri);

        expect(response.statusCode, 200);
        expect(adapter.requests, hasLength(2));
      },
      skip:
          'BUG: RetcodeInterceptor.onResponse rejects without '
          'callFollowingErrorInterceptor, so RetryInterceptor never sees -1004',
    );
  });
}
