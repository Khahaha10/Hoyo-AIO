import 'package:hoyo_aio/features/notifications/data/notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_permission_provider.g.dart';

@Riverpod(keepAlive: true)
class NotificationPermission extends _$NotificationPermission {
  @override
  Future<bool> build() => ref.watch(notificationServiceProvider).isEnabled();

  Future<void> recheck() async {
    final service = ref.read(notificationServiceProvider);
    state = await AsyncValue.guard(service.isEnabled);
  }

  Future<void> request() async {
    final service = ref.read(notificationServiceProvider);
    final granted = await service.requestPermission();
    if (!granted) await service.openSystemSettings();
    await recheck();
  }
}
