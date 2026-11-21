import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_kind.dart';

part 'planned_notification.freezed.dart';

enum PlannedAlert {
  staminaThreshold,
  staminaFull,
  expeditionsDone,
  currencyFull,
  transformerReady,
  dailyReminder,
}

@freezed
abstract class PlannedNotification with _$PlannedNotification {
  const factory PlannedNotification({
    required int id,
    required PlannedAlert alert,
    required DateTime at,
    Game? game,
    String? roleUid,
    String? roleName,
    int? value,
    int? max,
  }) = _PlannedNotification;

  const PlannedNotification._();

  NotificationKind get kind => switch (alert) {
    PlannedAlert.staminaThreshold ||
    PlannedAlert.staminaFull => NotificationKind.stamina,
    PlannedAlert.expeditionsDone => NotificationKind.expeditions,
    PlannedAlert.currencyFull => NotificationKind.currency,
    PlannedAlert.transformerReady => NotificationKind.transformer,
    PlannedAlert.dailyReminder => NotificationKind.dailyReminder,
  };
}
