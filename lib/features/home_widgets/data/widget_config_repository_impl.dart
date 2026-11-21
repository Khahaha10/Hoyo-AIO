import 'dart:convert';

import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/features/home_widgets/domain/home_widget_repositories.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'widget_config_repository_impl.g.dart';

class WidgetConfigRepositoryImpl implements WidgetConfigRepository {
  const WidgetConfigRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<WidgetConfigSnapshot>> all() async {
    final rows = await _db.select(_db.widgetConfigs).get();
    return [
      for (final row in rows)
        WidgetConfigSnapshot(
          widgetId: row.widgetId,
          size: row.size.name,
          roleId: row.roleId,
          theme: row.theme.name,
          opacity: row.opacity,
          accent: row.accent,
          fontSize: row.fontSize.name,
          visibleItems: _items(row.visibleItems),
        ),
    ];
  }

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
