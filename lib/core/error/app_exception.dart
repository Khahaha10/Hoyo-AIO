sealed class AppException implements Exception {
  const AppException();
}

final class NetworkException extends AppException {
  const NetworkException();
}

final class TimeoutException extends AppException {
  const TimeoutException();
}

final class CookieExpiredException extends AppException {
  const CookieExpiredException({this.retcode});

  final int? retcode;
}

final class CaptchaRequiredException extends AppException {
  const CaptchaRequiredException();
}

final class AlreadyCheckedInException extends AppException {
  const AlreadyCheckedInException();
}

final class RateLimitedException extends AppException {
  const RateLimitedException({required this.retryable});

  final bool retryable;
}

final class NoRolesException extends AppException {
  const NoRolesException({this.retcode});

  final int? retcode;
}

final class ForbiddenHostException extends AppException {
  const ForbiddenHostException(this.host);

  final String host;
}

final class AuthkeyExpiredException extends AppException {
  const AuthkeyExpiredException();
}

final class ServerException extends AppException {
  const ServerException({required this.retcode, this.message});

  final int retcode;
  final String? message;
}

final class ParseException extends AppException {
  const ParseException([this.detail]);

  final String? detail;
}

final class UnknownException extends AppException {
  const UnknownException([this.cause]);

  final Object? cause;
}
