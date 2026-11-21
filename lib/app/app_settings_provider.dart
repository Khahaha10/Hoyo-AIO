import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_settings_provider.g.dart';

@immutable
class AppPreferences {
  const AppPreferences({required this.themeMode, required this.locale});

  static const fallback = AppPreferences(
    themeMode: ThemeMode.system,
    locale: null,
  );

  final ThemeMode themeMode;
  final Locale? locale;
}

@Riverpod(keepAlive: true)
Stream<AppPreferences> appPreferences(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(
    db.appSettings,
  )..where((s) => s.id.equals(1))).watchSingle().map(
    (row) => AppPreferences(
      themeMode: switch (row.themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      locale: row.localeCode == null ? null : Locale(row.localeCode!),
    ),
  );
}
