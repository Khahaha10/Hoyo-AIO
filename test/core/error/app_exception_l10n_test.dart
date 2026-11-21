import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/error/app_exception_l10n.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('every AppException has a localized message', () {
    final cases = <AppException, String>{
      const CookieExpiredException(): l10n.errorCookieExpired,
      const NetworkException(): l10n.errorNetwork,
      const TimeoutException(): l10n.errorTimeout,
      const RateLimitedException(retryable: true): l10n.errorRateLimited,
      const NoRolesException(): l10n.errorNoRoles,
      const CaptchaRequiredException(): l10n.errorCaptcha,
      const AuthkeyExpiredException(): l10n.errorAuthkeyExpired,
      const ServerException(retcode: 42): l10n.errorServer(42),
      const AlreadyCheckedInException(): l10n.errorUnknown,
      const ForbiddenHostException('x'): l10n.errorUnknown,
      const ParseException(): l10n.errorUnknown,
      const UnknownException(): l10n.errorUnknown,
    };

    for (final MapEntry(key: error, value: message) in cases.entries) {
      expect(error.localizedMessage(l10n), message);
    }
    expect(l10n.errorServer(42), contains('42'));
  });
}
