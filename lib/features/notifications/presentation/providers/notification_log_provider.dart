import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/notifications/data/notification_log_repository_impl.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_log_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_log_provider.g.dart';

@riverpod
Stream<List<NotificationLogEntry>> notificationLog(Ref ref) {
  final now = ref.watch(clockTickProvider).value ?? ref.watch(clockProvider)();
  return ref.watch(notificationLogRepositoryProvider).watchDelivered(now);
}

@riverpod
int unreadNotificationCount(Ref ref) =>
    ref.watch(notificationLogProvider).value?.where((e) => !e.read).length ?? 0;
