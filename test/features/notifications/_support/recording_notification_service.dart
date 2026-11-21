import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/notifications/data/notification_service.dart';

class RecordingNotificationService extends NotificationService {
  RecordingNotificationService({this.enabled = true, this.grant = true})
    : super(FlutterLocalNotificationsPlugin());

  bool enabled;
  bool grant;
  final scheduled = <List<ScheduledMessage>>[];
  var permissionRequests = 0;
  var settingsOpened = 0;
  final syncedLocales = <String>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> syncChannels(AppLocalizations l10n) async =>
      syncedLocales.add(l10n.localeName);

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    if (grant) enabled = true;
    return grant;
  }

  @override
  Future<void> openSystemSettings() async => settingsOpened++;

  @override
  Future<String?> launchPayload() async => null;

  @override
  Future<void> replaceScheduled(List<ScheduledMessage> messages) async =>
      scheduled.add(messages);
}
