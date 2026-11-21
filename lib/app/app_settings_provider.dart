import 'package:drift/drift.dart' show Value;
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_settings_provider.g.dart';

enum AppAccent {
  match,
  lime,
  neutral;

  static const neutralColor = Color(0xFF8A93A3);
}

@immutable
class AppPreferences {
  const AppPreferences({
    required this.themeMode,
    required this.locale,
    required this.onboardingSeen,
    this.accent = AppAccent.lime,
    this.dynamicColor = false,
  });

  static const fallback = AppPreferences(
    themeMode: ThemeMode.system,
    locale: null,
    onboardingSeen: false,
  );

  final ThemeMode themeMode;
  final Locale? locale;
  final bool onboardingSeen;
  final AppAccent accent;
  final bool dynamicColor;
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
      locale: switch (row.localeCode) {
        final code? => Locale(code),
        null => null,
      },
      onboardingSeen: row.onboardingSeen,
      accent: AppAccent.values.asNameMap()[row.accent] ?? AppAccent.lime,
      dynamicColor: row.dynamicColor,
    ),
  );
}

@Riverpod(keepAlive: true)
class AppSettingsActions extends _$AppSettingsActions {
  @override
  void build() {}

  Future<void> _write(AppSettingsCompanion values) {
    final db = ref.read(appDatabaseProvider);
    return (db.update(
      db.appSettings,
    )..where((s) => s.id.equals(1))).write(values);
  }

  Future<void> setThemeMode(ThemeMode mode) => _write(
    AppSettingsCompanion(
      themeMode: Value(switch (mode) {
        ThemeMode.system => AppThemeMode.system,
        ThemeMode.light => AppThemeMode.light,
        ThemeMode.dark => AppThemeMode.dark,
      }),
    ),
  );

  Future<void> setAccent(AppAccent accent) =>
      _write(AppSettingsCompanion(accent: Value(accent.name)));

  Future<void> setDynamicColor({required bool enabled}) =>
      _write(AppSettingsCompanion(dynamicColor: Value(enabled)));

  Future<void> setLocale(String? languageCode) =>
      _write(AppSettingsCompanion(localeCode: Value(languageCode)));
}
