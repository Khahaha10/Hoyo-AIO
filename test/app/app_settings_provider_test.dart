import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/app_settings_provider.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:material_ui/material_ui.dart';

import '../features/onboarding/_support/pump_onboarding.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = openMemoryDatabase();
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
  });

  Future<AppPreferences> next() async {
    final sub = container.listen(appPreferencesProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    return container.read(appPreferencesProvider.future);
  }

  test('defaults map to system theme, no locale and lime accent', () async {
    final prefs = await next();

    expect(prefs.themeMode, ThemeMode.system);
    expect(prefs.locale, isNull);
    expect(prefs.onboardingSeen, isFalse);
    expect(prefs.accent, AppAccent.lime);
    expect(prefs.dynamicColor, isFalse);
  });

  test('actions persist theme, accent, dynamic color and locale', () async {
    final actions = container.read(appSettingsActionsProvider.notifier);

    for (final mode in ThemeMode.values) {
      await actions.setThemeMode(mode);
      expect((await next()).themeMode, mode);
    }
    await actions.setAccent(AppAccent.neutral);
    await actions.setDynamicColor(enabled: true);
    await actions.setLocale('id');
    final prefs = await next();

    expect(prefs.accent, AppAccent.neutral);
    expect(prefs.dynamicColor, isTrue);
    expect(prefs.locale, const Locale('id'));
  });

  test('an unknown stored accent falls back to lime', () async {
    await container
        .read(appSettingsActionsProvider.notifier)
        .setAccent(AppAccent.match);
    await (db.update(db.appSettings))
        .write(const AppSettingsCompanion(accent: Value('purple')));

    expect((await next()).accent, AppAccent.lime);
  });

  test('fallback preferences are system theme and not onboarded', () {
    expect(AppPreferences.fallback.themeMode, ThemeMode.system);
    expect(AppPreferences.fallback.onboardingSeen, isFalse);
  });
}
