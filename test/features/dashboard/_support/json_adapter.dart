import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class JsonAdapter implements HttpClientAdapter {
  JsonAdapter(this.reply);

  final Object Function(RequestOptions options) reply;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = reply(options);
    if (body is Exception) throw body;
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
