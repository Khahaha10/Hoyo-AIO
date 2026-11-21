import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';

extension AppExceptionMessage on AppException {
  String localizedMessage(AppLocalizations l10n) => switch (this) {
    CookieExpiredException() => l10n.errorCookieExpired,
    NetworkException() => l10n.errorNetwork,
    TimeoutException() => l10n.errorTimeout,
    RateLimitedException() => l10n.errorRateLimited,
    NoRolesException() => l10n.errorNoRoles,
    CaptchaRequiredException() => l10n.errorCaptcha,
    ServerException(:final retcode) => l10n.errorServer(retcode),
    AlreadyCheckedInException() ||
    ForbiddenHostException() ||
    ParseException() ||
    UnknownException() => l10n.errorUnknown,
  };
}
