import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/logging/app_logger.dart';
import 'package:hoyo_aio/core/logging/redactor.dart';
import 'package:hoyo_aio/core/network/interceptors/redacting_log_interceptor.dart';
import 'package:logger/logger.dart';

const _secretToken = 'zzSECRETtoken';
const _secretAuthkey = 'zzSECRETauthkey';
const _uid = '800000123';

const _cookie =
    'ltuid_v2=$_uid; ltoken_v2=$_secretToken; cookie_token_v2=$_secretToken; '
    'account_mid_v2=$_secretToken; ltmid_v2=$_secretToken';

final _leaks = [_secretToken, _secretAuthkey, _uid];

void _expectClean(Iterable<String> lines) {
  expect(lines, isNotEmpty);
  for (final line in lines) {
    for (final leak in _leaks) {
      expect(line, isNot(contains(leak)), reason: line);
    }
  }
}

class _Memory extends LogOutput {
  final lines = <String>[];

  @override
  void output(OutputEvent event) => lines.addAll(event.lines);
}

class _Next extends RequestInterceptorHandler {
  @override
  void next(RequestOptions requestOptions) {}
}

class _NextResponse extends ResponseInterceptorHandler {
  @override
  void next(Response<dynamic> response) {}
}

class _NextError extends ErrorInterceptorHandler {
  @override
  void next(DioException err) {}
}

void main() {
  group('Redactor.redact', () {
    test('masks every cookie key and keeps the key names', () {
      final out = Redactor.redact('Cookie: $_cookie');

      _expectClean([out]);
      expect(out, contains('ltoken_v2=***'));
    });

    test('masks JSON style secrets and the authkey', () {
      final out = Redactor.redact(
        '{"authkey": "$_secretAuthkey", "stoken":"$_secretToken"}',
      );

      _expectClean([out]);
    });

    test('masks uid values to the last three digits', () {
      expect(Redactor.redact('uid=$_uid'), 'uid=***123');
      expect(Redactor.redact('"role_id": $_uid'), '"role_id": ***123');
    });

    test('leaves harmless text alone', () {
      expect(Redactor.redact('retcode=0 ok'), 'retcode=0 ok');
    });
  });

  group('Redactor.maskId', () {
    test('short ids are fully masked', () {
      expect(Redactor.maskId('12'), '***');
      expect(Redactor.maskId('123'), '***');
      expect(Redactor.maskId('1234'), '***234');
    });
  });

  group('Redactor.redactUri', () {
    test('removes query secrets and the fragment', () {
      final out = Redactor.redactUri(
        Uri.parse(
          'https://${HoyolabConfig.gachaHosts.values.first}/log'
          '?authkey=$_secretAuthkey&uid=$_uid#authkey=$_secretAuthkey',
        ),
      );

      _expectClean([out]);
      expect(out, isNot(contains('#')));
    });
  });

  group('RedactingLogInterceptor', () {
    final uri = Uri.https(HoyolabConfig.gameRecordHost, '/x', {
      'authkey': _secretAuthkey,
      'role_id': _uid,
    });

    test('request, response and error lines never leak secrets', () {
      final lines = <String>[];
      final interceptor = RedactingLogInterceptor(
        sink: (message, {isError = false}) => lines.add(message),
        verbose: true,
      );
      final options = RequestOptions(
        path: uri.toString(),
        headers: {'Cookie': _cookie},
      );

      interceptor
        ..onRequest(options, _Next())
        ..onResponse(
          Response<Object?>(
            requestOptions: options,
            statusCode: 200,
            data: {'retcode': 0},
          ),
          _NextResponse(),
        )
        ..onError(
          DioException(
            requestOptions: options,
            error: const CookieExpiredException(),
          ),
          _NextError(),
        );

      expect(lines, hasLength(3));
      _expectClean(lines);
    });

    test('non-verbose mode logs only errors', () {
      final errors = <bool>[];
      final interceptor = RedactingLogInterceptor(
        sink: (message, {isError = false}) => errors.add(isError),
        verbose: false,
      );
      final options = RequestOptions(path: uri.toString());

      interceptor
        ..onRequest(options, _Next())
        ..onResponse(
          Response<Object?>(requestOptions: options, statusCode: 200),
          _NextResponse(),
        )
        ..onError(DioException(requestOptions: options), _NextError());

      expect(errors, [true]);
    });
  });

  group('AppLogger', () {
    test('every level redacts message and error text', () {
      final output = _Memory();
      final logger = AppLogger(verbose: true, output: output);

      logger
        ..debug('Cookie: $_cookie')
        ..info('authkey=$_secretAuthkey')
        ..warning('uid=$_uid')
        ..error('ltoken=$_secretToken', const FormatException('x'))
        ..network('stoken=$_secretToken')
        ..network('authkey=$_secretAuthkey', isError: true);

      expect(output.lines.length, greaterThanOrEqualTo(6));
      _expectClean(output.lines);
    });

    test('release logger drops debug and info lines', () {
      final output = _Memory();
      final logger = AppLogger(verbose: false, output: output);

      logger
        ..debug('debug line')
        ..info('info line')
        ..network('network line')
        ..warning('warning line');

      expect(output.lines.join('\n'), isNot(contains('debug line')));
      expect(output.lines.join('\n'), isNot(contains('info line')));
      expect(output.lines.join('\n'), isNot(contains('network line')));
      expect(output.lines.join('\n'), contains('warning line'));
    });
  });
}
