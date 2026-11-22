import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_settings.freezed.dart';
part 'notification_settings.g.dart';

@freezed
abstract class NotificationSettings with _$NotificationSettings {
  const factory NotificationSettings({
    @Default(true) bool enabled,
    @Default(true) bool stamina,
    @Default(90) int staminaThresholdPercent,
    @Default(true) bool expeditions,
    @Default(true) bool currency,
    @Default(true) bool transformer,
    @Default(false) bool dailyReminder,
    @Default(21 * 60) int dailyReminderMinutes,
    @Default(true) bool checkInResult,
    @Default(true) bool codes,
    @Default(true) bool events,
    @Default(false) bool endgameReset,
    @Default(false) bool quietHours,
    @Default(23 * 60) int quietStartMinutes,
    @Default(7 * 60) int quietEndMinutes,
  }) = _NotificationSettings;

  const NotificationSettings._();

  int get activeAlertCount => [
    stamina,
    expeditions,
    currency,
    transformer,
    dailyReminder,
    checkInResult,
    codes,
    events,
    endgameReset,
    true,
  ].where((on) => on).length;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsFromJson(json);
}
