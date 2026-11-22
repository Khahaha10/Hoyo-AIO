import 'package:hoyo_aio/app/app_settings_provider.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/selected_role_provider.dart';
import 'package:hoyo_aio/features/dashboard/data/notes_repository_impl.dart';
import 'package:hoyo_aio/features/databook/data/chronicle_repository_impl.dart';
import 'package:hoyo_aio/features/notifications/data/notification_scheduler_impl.dart';
import 'package:hoyo_aio/features/notifications/data/notification_settings_repository_impl.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_settings.dart';
import 'package:hoyo_aio/features/notifications/domain/reschedule_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_sync_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<NotificationSettings> notificationSettings(Ref ref) =>
    ref.watch(notificationSettingsRepositoryProvider).watch();

@Riverpod(keepAlive: true)
Stream<int> noteSnapshotVersion(Ref ref) async* {
  var version = 0;
  yield version;
  await for (final _ in ref.watch(appDatabaseProvider).noteSnapshotChanges()) {
    yield ++version;
  }
}

@Riverpod(keepAlive: true)
Stream<int> chronicleCacheVersion(Ref ref) async* {
  var version = 0;
  yield version;
  await for (final _
      in ref.watch(appDatabaseProvider).chronicleCacheChanges()) {
    yield ++version;
  }
}

@Riverpod(keepAlive: true)
RescheduleNotifications rescheduleNotifications(Ref ref) =>
    RescheduleNotifications(
      ref.watch(notesRepositoryProvider),
      ref.watch(chronicleRepositoryProvider),
      ref.watch(notificationSchedulerProvider),
      ref.watch(clockProvider),
    );

@Riverpod(keepAlive: true)
Future<int> notificationSync(Ref ref) async {
  final roles = ref.watch(dashboardRolesProvider);
  final settings = ref.watch(notificationSettingsProvider).value;
  ref.watch(noteSnapshotVersionProvider);
  ref.watch(chronicleCacheVersionProvider);
  final locale = ref.watch(appPreferencesProvider).value?.locale;
  if (settings == null) return 0;
  final planned = await ref.read(rescheduleNotificationsProvider)(
    roles: roles,
    settings: settings,
    localeCode: locale?.languageCode,
  );
  return planned.length;
}
