import 'package:hoyo_aio/features/notifications/domain/notification_settings.dart';
import 'package:hoyo_aio/features/notifications/domain/planned_notification.dart';

abstract interface class NotificationSettingsRepository {
  Stream<NotificationSettings> watch();

  Future<NotificationSettings> read();

  Future<void> save(NotificationSettings settings);
}

abstract interface class NotificationScheduler {
  Future<void> replaceAll(
    List<PlannedNotification> planned, {
    String? localeCode,
  });
}
