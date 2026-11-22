import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/error/retcode_mapper.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';

typedef CookieExpiredCallback = void Function(String accountId);

class RetcodeInterceptor extends Interceptor {
  RetcodeInterceptor({this.onCookieExpired});

  final CookieExpiredCallback? onCookieExpired;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final data = response.data;
    final retcode = parseRetcode(data);
    if (retcode == null) {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: const ParseException('missing retcode'),
        ),
      );
      return;
    }
    final message = data is Map ? data['message'] as String? : null;
    final error = exceptionForRetcode(retcode, message: message);
    if (error == null) {
      handler.next(response);
      return;
    }
    final accountId = response.requestOptions.hoyolabAccountId;
    if (error is CookieExpiredException &&
        accountId != null &&
        !response.requestOptions.hoyolabKeepAccountOnExpired) {
      onCookieExpired?.call(accountId);
    }
    handler.reject(
      DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: error,
      ),
    );
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is AppException) {
      handler.next(err);
      return;
    }
    handler.next(err.copyWith(error: mapDioError(err)));
  }
}

AppException mapDioError(DioException err) {
  final error = err.error;
  if (error is AppException) return error;
  return switch (err.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const TimeoutException(),
    DioExceptionType.connectionError => const NetworkException(),
    DioExceptionType.badResponse => ServerException(
      retcode: err.response?.statusCode ?? -1,
      message: err.response?.statusMessage,
    ),
    DioExceptionType.unknown when error is SocketException =>
      const NetworkException(),
    _ => UnknownException(err.type),
  };
}
