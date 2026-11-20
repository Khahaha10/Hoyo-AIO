import 'package:dio/dio.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';

class RateLimitInterceptor extends Interceptor {
  RateLimitInterceptor({
    this.minInterval = const Duration(milliseconds: 1500),
    DateTime Function()? now,
    Future<void> Function(Duration)? wait,
  }) : _now = now ?? DateTime.now,
       _wait = wait ?? Future<void>.delayed;

  final Duration minInterval;
  final DateTime Function() _now;
  final Future<void> Function(Duration) _wait;
  final _nextAllowed = <String, DateTime>{};

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final key =
        '${options.hoyolabAccountId}|${options.uri.host}${options.uri.path}';
    final now = _now();
    final allowedAt = _nextAllowed[key];
    final start = allowedAt != null && allowedAt.isAfter(now) ? allowedAt : now;
    _nextAllowed[key] = start.add(minInterval);
    if (start.isAfter(now)) await _wait(start.difference(now));
    handler.next(options);
  }
}
