import 'package:dio/dio.dart';
import 'package:hoyo_aio/core/error/retcode_mapper.dart';
import 'package:hoyo_aio/core/logging/redactor.dart';

typedef LogSink = void Function(String message, {bool isError});

class RedactingLogInterceptor extends Interceptor {
  RedactingLogInterceptor({required this.sink, required this.verbose});

  final LogSink sink;
  final bool verbose;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (verbose) {
      sink('→ ${options.method} ${Redactor.redactUri(options.uri)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (verbose) {
      final options = response.requestOptions;
      sink(
        '← ${response.statusCode} ${options.method} '
        '${Redactor.redactUri(options.uri)} '
        'retcode=${parseRetcode(response.data)}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    sink(
      '✕ ${options.method} ${Redactor.redactUri(options.uri)} '
      'status=${err.response?.statusCode} '
      'retcode=${parseRetcode(err.response?.data)} '
      'error=${err.error.runtimeType}',
      isError: true,
    );
    handler.next(err);
  }
}
