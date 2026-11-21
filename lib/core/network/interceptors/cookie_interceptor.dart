import 'package:dio/dio.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';
import 'package:hoyo_aio/core/network/interceptors/host_allowlist_interceptor.dart';

typedef CookieProvider = Future<String?> Function(String accountId);

class CookieInterceptor extends Interceptor {
  CookieInterceptor(this._cookies);

  final CookieProvider _cookies;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers.remove('Cookie');
    final accountId = options.hoyolabAccountId;
    if (!isAllowedHoyolabUri(options.uri)) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: ForbiddenHostException(options.uri.host),
        ),
      );
      return;
    }
    if (accountId == null ||
        HoyolabConfig.gachaHosts.containsValue(options.uri.host)) {
      handler.next(options);
      return;
    }
    final cookie = await _cookies(accountId);
    if (cookie == null || cookie.isEmpty) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: const CookieExpiredException(),
        ),
      );
      return;
    }
    options.headers['Cookie'] = cookie;
    handler.next(options);
  }
}
