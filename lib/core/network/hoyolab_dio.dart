import 'package:dio/dio.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/dynamic_secret.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/interceptors/cookie_interceptor.dart';
import 'package:hoyo_aio/core/network/interceptors/host_allowlist_interceptor.dart';
import 'package:hoyo_aio/core/network/interceptors/hoyolab_headers_interceptor.dart';
import 'package:hoyo_aio/core/network/interceptors/rate_limit_interceptor.dart';
import 'package:hoyo_aio/core/network/interceptors/redacting_log_interceptor.dart';
import 'package:hoyo_aio/core/network/interceptors/retcode_interceptor.dart';
import 'package:hoyo_aio/core/network/interceptors/retry_interceptor.dart';

abstract final class NetworkTimeouts {
  static const connect = Duration(seconds: 15);
  static const send = Duration(seconds: 15);
  static const receive = Duration(seconds: 20);
}

Dio buildHoyolabDio({
  required CookieProvider cookies,
  required LogSink log,
  required bool verboseLogging,
  String Function() language = _defaultLanguage,
  DynamicSecret? dynamicSecret,
  HttpClientAdapter? adapter,
}) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: NetworkTimeouts.connect,
      sendTimeout: NetworkTimeouts.send,
      receiveTimeout: NetworkTimeouts.receive,
      followRedirects: false,
      maxRedirects: 0,
      responseType: ResponseType.json,
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    ),
  );
  if (adapter != null) dio.httpClientAdapter = adapter;
  dio.interceptors.addAll([
    RateLimitInterceptor(),
    HostAllowlistInterceptor(),
    HoyolabHeadersInterceptor(
      dynamicSecret: dynamicSecret ?? DynamicSecret(),
      language: language,
    ),
    CookieInterceptor(cookies),
    RetcodeInterceptor(),
    RetryInterceptor(dio),
    RedactingLogInterceptor(sink: log, verbose: verboseLogging),
  ]);
  return dio;
}

String _defaultLanguage() => HoyolabConfig.languageEnglish;

Future<T> guardHoyolab<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (e) {
    throw mapDioError(e);
  } on AppException {
    rethrow;
  } on FormatException catch (e) {
    throw ParseException(e.message);
  } on TypeError catch (e) {
    throw ParseException(e.toString());
  }
}
