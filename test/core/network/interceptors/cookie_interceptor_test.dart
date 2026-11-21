import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';
import 'package:hoyo_aio/core/network/interceptors/cookie_interceptor.dart';
import 'package:hoyo_aio/core/network/interceptors/host_allowlist_interceptor.dart';

class _Capture extends RequestInterceptorHandler {
  RequestOptions? passed;
  DioException? rejected;

  @override
  void next(RequestOptions requestOptions) => passed = requestOptions;

  @override
  void reject(DioException error, [bool callFollowing = false]) =>
      rejected = error;
}

RequestOptions _request(String url, {String? accountId}) => RequestOptions(
  path: url,
  headers: {'Cookie': 'stale=1'},
  extra: accountId == null
      ? {}
      : hoyolabOptions(
          accountId: accountId,
          profile: HeaderProfile.gameRecord,
        ).extra,
);

void main() {
  const host = HoyolabConfig.gameRecordHost;
  final reads = <String>[];

  CookieInterceptor interceptor(String? cookie) =>
      CookieInterceptor((id) async {
        reads.add(id);
        return cookie;
      });

  setUp(reads.clear);

  test('isAllowedHoyolabUri accepts only https allowlisted hosts', () {
    expect(isAllowedHoyolabUri(Uri.https(host, '/')), isTrue);
    expect(isAllowedHoyolabUri(Uri.http(host, '/')), isFalse);
    expect(isAllowedHoyolabUri(Uri.https('evil.$host', '/')), isFalse);
  });

  test('attaches the vault cookie and drops any preset Cookie', () async {
    final handler = _Capture();

    await interceptor('ltuid_v2=1; ltoken_v2=fake')
        .onRequest(_request('https://$host/x', accountId: '1'), handler);

    expect(handler.passed?.headers['Cookie'], 'ltuid_v2=1; ltoken_v2=fake');
  });

  test('rejects a foreign host on its own without reading the vault', () async {
    final handler = _Capture();

    await interceptor('x').onRequest(
      _request('https://evil.example.com/x', accountId: '1'),
      handler,
    );

    expect(handler.rejected?.error, isA<ForbiddenHostException>());
    expect(reads, isEmpty);
  });

  test('requests without account id go out without a cookie', () async {
    final handler = _Capture();

    await interceptor('x').onRequest(_request('https://$host/x'), handler);

    expect(handler.passed?.headers.containsKey('Cookie'), isFalse);
    expect(reads, isEmpty);
  });

  test('an empty vault cookie is rejected as expired', () async {
    final handler = _Capture();

    await interceptor('')
        .onRequest(_request('https://$host/x', accountId: '1'), handler);

    expect(handler.rejected?.error, isA<CookieExpiredException>());
  });

  test('HostAllowlistInterceptor rejects foreign hosts', () {
    final handler = _Capture();

    HostAllowlistInterceptor().onRequest(
      _request('https://evil.example.com/x'),
      handler,
    );

    expect(handler.rejected?.error, isA<ForbiddenHostException>());
  });
}
