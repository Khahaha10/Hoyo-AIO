import 'dart:ui' show PlatformDispatcher;

import 'package:hoyo_aio/core/l10n/l10n.dart';

AppLocalizations resolveL10n(String? localeCode) {
  const supported = AppLocalizations.supportedLocales;
  final wanted = localeCode ?? PlatformDispatcher.instance.locale.languageCode;
  final locale =
      supported.where((l) => l.languageCode == wanted).firstOrNull ??
      supported.first;
  return lookupAppLocalizations(locale);
}
