import 'package:dio/dio.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';

class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._dio, {
    this.backoff = const [Duration(seconds: 1), Duration(seconds: 3)],
    Future<void> Function(Duration)? wait,
  }) : _wait = wait ?? Future<void>.delayed;

  final Dio _dio;
  final List<Duration> backoff;
  final Future<void> Function(Duration) _wait;

  static bool isRetryable(Object? error) => switch (error) {
    NetworkException() || TimeoutException() => true,
    RateLimitedException(:final retryable) => retryable,
    _ => false,
  };

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = err.requestOptions.hoyolabRetryCount;
    if (!isRetryable(err.error) || attempt >= backoff.length) {
      handler.next(err);
      return;
    }
    await _wait(backoff[attempt]);
    final options = err.requestOptions
      ..extra[HoyolabExtras.retryCount] = attempt + 1;
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
