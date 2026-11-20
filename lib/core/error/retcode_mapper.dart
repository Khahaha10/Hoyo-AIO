import 'package:hoyo_aio/core/error/app_exception.dart';

abstract final class Retcode {
  static const success = 0;
  static const notLoggedIn = -100;
  static const notLoggedIn2 = 10001;
  static const notLoggedIn3 = 10103;
  static const wrongAccount = 10104;
  static const dataNotPublic = 10102;
  static const tooManyRequests = 10101;
  static const tooFast = -1004;
  static const accountNotFound = -10002;
  static const characterInfo = 1009;
  static const internalError = -1;
  static const invalidLanguage = -108;
  static const invalidInput = -502;
  static const alreadyClaimed = -5003;
  static const alreadyCheckedIntoHoyolab = 2001;
}

int? parseRetcode(Object? data) {
  if (data is! Map) return null;
  final value = data['retcode'];
  return switch (value) {
    final int code => code,
    final String text => int.tryParse(text),
    _ => null,
  };
}

AppException? exceptionForRetcode(int retcode, {String? message}) =>
    switch (retcode) {
      Retcode.success => null,
      Retcode.notLoggedIn ||
      Retcode.notLoggedIn2 ||
      Retcode.notLoggedIn3 => CookieExpiredException(retcode: retcode),
      Retcode.wrongAccount ||
      Retcode.accountNotFound => NoRolesException(retcode: retcode),
      Retcode.tooManyRequests => const RateLimitedException(retryable: false),
      Retcode.tooFast => const RateLimitedException(retryable: true),
      Retcode.alreadyClaimed ||
      Retcode.alreadyCheckedIntoHoyolab => const AlreadyCheckedInException(),
      Retcode.invalidInput => ParseException('retcode $retcode'),
      _ => ServerException(retcode: retcode, message: message),
    };
