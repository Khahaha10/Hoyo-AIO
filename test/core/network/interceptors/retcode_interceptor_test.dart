import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/error/retcode_mapper.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';
import 'package:hoyo_aio/core/network/interceptors/retcode_interceptor.dart';

import '../_support/fake_adapter.dart';

final _options = RequestOptions(path: '/x');

DioException _dioError(DioExceptionType type, {Object? error, int? status}) =>
    DioException(
      requestOptions: _options,
      type: type,
      error: error,
      response: status == null
          ? null
          : Response<Object?>(
              requestOptions: _options,
              statusCode: status,
              statusMessage: 'status $status',
            ),
    );

void main() {
  group('parseRetcode', () {
    test('reads int and numeric string retcodes', () {
      expect(parseRetcode({'retcode': -100}), -100);
      expect(parseRetcode({'retcode': '10001'}), 10001);
    });

    test('returns null for non-maps, missing or invalid retcodes', () {
      expect(parseRetcode(null), isNull);
      expect(parseRetcode('text'), isNull);
      expect(parseRetcode({'data': 1}), isNull);
      expect(parseRetcode({'retcode': 'abc'}), isNull);
      expect(parseRetcode({'retcode': 1.5}), isNull);
    });
  });

  group('exceptionForRetcode', () {
    test('maps every documented retcode', () {
      expect(exceptionForRetcode(Retcode.success), isNull);
      for (final code in [
        Retcode.notLoggedIn,
        Retcode.notLoggedIn2,
        Retcode.notLoggedIn3,
      ]) {
        final error = exceptionForRetcode(code);
        expect(error, isA<CookieExpiredException>());
        expect((error as CookieExpiredException).retcode, code);
      }
      for (final code in [Retcode.wrongAccount, Retcode.accountNotFound]) {
        final error = exceptionForRetcode(code);
        expect(error, isA<NoRolesException>());
        expect((error as NoRolesException).retcode, code);
      }
      final tooMany = exceptionForRetcode(Retcode.tooManyRequests);
      expect((tooMany as RateLimitedException).retryable, isFalse);
      final tooFast = exceptionForRetcode(Retcode.tooFast);
      expect((tooFast as RateLimitedException).retryable, isTrue);
      expect(
        exceptionForRetcode(Retcode.alreadyClaimed),
        isA<AlreadyCheckedInException>(),
      );
      expect(
        exceptionForRetcode(Retcode.alreadyCheckedIntoHoyolab),
        isA<AlreadyCheckedInException>(),
      );
      expect(
        exceptionForRetcode(Retcode.invalidInput),
        isA<ParseException>(),
      );
    });

    test('unknown retcodes become ServerException with the message', () {
      final error = exceptionForRetcode(Retcode.dataNotPublic, message: 'm');

      expect(error, isA<ServerException>());
      expect((error as ServerException).retcode, Retcode.dataNotPublic);
      expect(error.message, 'm');
    });
  });

  group('mapDioError', () {
    test('keeps an AppException carried by the DioException', () {
      final error = mapDioError(
        _dioError(DioExceptionType.unknown, error: const CaptchaRequiredException()),
      );

      expect(error, isA<CaptchaRequiredException>());
    });

    test('maps timeouts, connection and socket errors', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(mapDioError(_dioError(type)), isA<TimeoutException>());
      }
      expect(
        mapDioError(_dioError(DioExceptionType.connectionError)),
        isA<NetworkException>(),
      );
      expect(
        mapDioError(
          _dioError(
            DioExceptionType.unknown,
            error: const SocketException('x'),
          ),
        ),
        isA<NetworkException>(),
      );
    });

    test('maps a bad HTTP status to ServerException', () {
      final error = mapDioError(
        _dioError(DioExceptionType.badResponse, status: 503),
      );

      expect((error as ServerException).retcode, 503);
      expect(error.message, 'status 503');
    });

    test('maps a bad response without status to retcode -1', () {
      final error = mapDioError(_dioError(DioExceptionType.badResponse));

      expect((error as ServerException).retcode, -1);
    });

    test('maps anything else to UnknownException', () {
      expect(
        mapDioError(_dioError(DioExceptionType.cancel)),
        isA<UnknownException>(),
      );
    });
  });

  group('RetcodeInterceptor', () {
    Dio dio(FakeAdapter adapter, List<String> expired) {
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(RetcodeInterceptor(onCookieExpired: expired.add));
      return dio;
    }

    final uri = Uri.https(HoyolabConfig.gameRecordHost, '/x');

    test('passes a success retcode through', () async {
      final response = await dio(
        FakeAdapter.json({'retcode': 0, 'data': 1}),
        [],
      ).getUri<Map<String, dynamic>>(uri);

      expect(response.data?['data'], 1);
    });

    test('does not report expiry when there is no account id', () async {
      final expired = <String>[];

      await expectLater(
        dio(FakeAdapter.json({'retcode': -100}), expired).getUri<Object?>(uri),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<CookieExpiredException>(),
          ),
        ),
      );
      expect(expired, isEmpty);
    });

    test('reports expiry for the request account', () async {
      final expired = <String>[];

      await expectLater(
        dio(FakeAdapter.json({'retcode': 10001}), expired).getUri<Object?>(
          uri,
          options: hoyolabOptions(
            accountId: '800000001',
            profile: HeaderProfile.gameRecord,
          ),
        ),
        throwsA(isA<DioException>()),
      );
      expect(expired, ['800000001']);
    });
  });
}
