@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/features/settings/presentation/settings_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../features/settings/_support/settings_support.dart';

void main() {
  for (final (name, dark, locale, scale) in [
    ('light', false, const Locale('en'), 1.0),
    ('dark', true, const Locale('en'), 1.0),
    ('id', false, const Locale('id'), 1.3),
  ]) {
    testWidgets('settings screen $name', (tester) async {
      await pumpRouted(
        tester,
        settingsRouter(const SettingsScreen()),
        overrides: settingsOverrides(),
        dark: dark,
        locale: locale,
        textScale: scale,
      );

      await expectLater(
        find.byType(SettingsScreen),
        matchesGoldenFile('settings_$name.png'),
      );
      await drainTimers(tester);
    });
  }
}
