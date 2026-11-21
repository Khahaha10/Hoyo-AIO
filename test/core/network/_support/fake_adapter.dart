import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef FakeReply = Object Function(RequestOptions options);

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this._reply);

  FakeAdapter.json(Map<String, Object?> body) : _reply = ((_) => body);

  final FakeReply _reply;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final reply = _reply(options);
    if (reply is Exception) throw reply;
    if (reply is ResponseBody) return reply;
    return ResponseBody.fromString(
      jsonEncode(reply),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
