import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/features/home_widgets/domain/home_widget_repositories.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'widget_config_repository_impl.g.dart';

class WidgetConfigRepositoryImpl implements WidgetConfigRepository {
  const WidgetConfigRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<WidgetConfigSnapshot>> all() =>
      _db.select(_db.widgetConfigs).map(_toSnapshot).get();

  @override
  Stream<List<WidgetConfigSnapshot>> watch() =>
      _db.select(_db.widgetConfigs).map(_toSnapshot).watch();

  @override
  Future<void> save(
    WidgetConfigSnapshot config, {
    required String? accountId,
  }) => _db
      .into(_db.widgetConfigs)
      .insertOnConflictUpdate(
        WidgetConfigsCompanion.insert(
          widgetId: Value(config.widgetId),
          size: WidgetSize.values.byName(config.size),
          accountId: Value(accountId),
          roleId: Value(config.roleId),
          theme: WidgetTheme.values.byName(config.theme),
          opacity: Value(config.opacity),
          accent: Value(config.accent),
          fontSize: WidgetFontSize.values.byName(config.fontSize),
          visibleItems: Value(jsonEncode(config.visibleItems)),
          updatedAt: DateTime.now(),
        ),
      );

  static WidgetConfigSnapshot _toSnapshot(WidgetConfig row) =>
      WidgetConfigSnapshot(
        widgetId: row.widgetId,
        size: row.size.name,
        roleId: row.roleId,
        theme: row.theme.name,
        opacity: row.opacity,
        accent: row.accent,
        fontSize: row.fontSize.name,
        visibleItems: _items(row.visibleItems),
      );

  static List<String> _items(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? [for (final item in decoded) '$item'] : const [];
    } on FormatException {
      return const [];
    }
  }
}

@Riverpod(keepAlive: true)
WidgetConfigRepository widgetConfigRepository(Ref ref) =>
    WidgetConfigRepositoryImpl(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
Stream<List<WidgetConfigSnapshot>> widgetConfigs(Ref ref) =>
    ref.watch(widgetConfigRepositoryProvider).watch();
