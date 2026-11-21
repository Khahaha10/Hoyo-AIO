import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hoyo_aio/core/network/interceptors/retcode_interceptor.dart';

typedef Responder = Object? Function(RequestOptions options);

class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.responder);

  final Responder responder;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = responder(options);
    if (body is DioException) throw body;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio fakeDio(FakeHttpAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  dio.interceptors.add(RetcodeInterceptor());
  return dio;
}
