import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';

part 'widget_snapshot.freezed.dart';
part 'widget_snapshot.g.dart';

@freezed
abstract class WidgetSnapshot with _$WidgetSnapshot {
  const factory WidgetSnapshot({
    required int version,
    required DateTime generatedAt,
    required List<WidgetRoleSnapshot> roles,
    required WidgetCheckIn checkIn,
    required List<WidgetConfigSnapshot> widgets,
    required Map<String, String> labels,
  }) = _WidgetSnapshot;

  factory WidgetSnapshot.fromJson(Map<String, dynamic> json) =>
      _$WidgetSnapshotFromJson(json);
}

@freezed
abstract class WidgetRoleSnapshot with _$WidgetRoleSnapshot {
  const factory WidgetRoleSnapshot({
    required int roleId,
    required Game game,
    required String uid,
    required String name,
    required DateTime fetchedAt,
    required bool stale,
    required WidgetStamina stamina,
    required List<WidgetItem> items,
  }) = _WidgetRoleSnapshot;

  factory WidgetRoleSnapshot.fromJson(Map<String, dynamic> json) =>
      _$WidgetRoleSnapshotFromJson(json);
}

@freezed
abstract class WidgetStamina with _$WidgetStamina {
  const factory WidgetStamina({
    required String key,
    required int current,
    required int max,
    required DateTime fetchedAt,
    required DateTime fullAt,
    required int recoverySeconds,
  }) = _WidgetStamina;

  factory WidgetStamina.fromJson(Map<String, dynamic> json) =>
      _$WidgetStaminaFromJson(json);
}

@freezed
abstract class WidgetItem with _$WidgetItem {
  const factory WidgetItem({
    required String key,
    int? value,
    int? max,
    DateTime? doneAt,
    String? state,
  }) = _WidgetItem;

  factory WidgetItem.fromJson(Map<String, dynamic> json) =>
      _$WidgetItemFromJson(json);
}

@freezed
abstract class WidgetCheckIn with _$WidgetCheckIn {
  const factory WidgetCheckIn({
    required String day,
    required int done,
    required int total,
  }) = _WidgetCheckIn;

  factory WidgetCheckIn.fromJson(Map<String, dynamic> json) =>
      _$WidgetCheckInFromJson(json);
}

@freezed
abstract class WidgetConfigSnapshot with _$WidgetConfigSnapshot {
  const factory WidgetConfigSnapshot({
    required int widgetId,
    required String size,
    required int? roleId,
    required String theme,
    required double opacity,
    required String accent,
    required String fontSize,
    required List<String> visibleItems,
  }) = _WidgetConfigSnapshot;

  factory WidgetConfigSnapshot.fromJson(Map<String, dynamic> json) =>
      _$WidgetConfigSnapshotFromJson(json);
}
