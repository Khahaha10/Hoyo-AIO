import 'package:dio/dio.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';

bool isAllowedHoyolabUri(Uri uri) =>
    uri.scheme == 'https' && HoyolabConfig.allowedHosts.contains(uri.host);

class HostAllowlistInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (isAllowedHoyolabUri(options.uri)) {
      handler.next(options);
      return;
    }
    handler.reject(
      DioException(
        requestOptions: options,
        error: ForbiddenHostException(options.uri.host),
      ),
    );
  }
}
