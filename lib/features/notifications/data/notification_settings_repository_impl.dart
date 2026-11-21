import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_repositories.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_settings.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_settings_repository_impl.g.dart';

class NotificationSettingsRepositoryImpl
    implements NotificationSettingsRepository {
  const NotificationSettingsRepositoryImpl(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$AppSettingsTable, AppSetting> get _row =>
      _db.select(_db.appSettings)..where((s) => s.id.equals(1));

  @override
  Stream<NotificationSettings> watch() =>
      _row.watchSingle().map((row) => _decode(row.notificationSettings));

  @override
  Future<NotificationSettings> read() async =>
      _decode((await _row.getSingle()).notificationSettings);

  @override
  Future<void> save(NotificationSettings settings) =>
      (_db.update(_db.appSettings)..where((s) => s.id.equals(1))).write(
        AppSettingsCompanion(
          notificationSettings: Value(jsonEncode(settings.toJson())),
        ),
      );

  static NotificationSettings _decode(String raw) {
    try {
      final json = jsonDecode(raw);
      return json is Map<String, dynamic>
          ? NotificationSettings.fromJson(json)
          : const NotificationSettings();
    } on FormatException {
      return const NotificationSettings();
    } on CheckedFromJsonException {
      return const NotificationSettings();
    }
  }
}

@Riverpod(keepAlive: true)
NotificationSettingsRepository notificationSettingsRepository(Ref ref) =>
    NotificationSettingsRepositoryImpl(ref.watch(appDatabaseProvider));
