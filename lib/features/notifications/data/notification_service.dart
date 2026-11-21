import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_kind.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_service.g.dart';

class NotificationService {
  NotificationService(this._plugin);

  static const androidIcon = 'ic_notification';

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initialized;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  Future<void> initialize() => _initialized ??= _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings(androidIcon),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
  );

  Future<void> syncChannels(AppLocalizations l10n) async {
    await initialize();
    final android = _android;
    if (android == null) return;
    for (final kind in NotificationKind.values) {
      final (name, description) = _channelText(kind, l10n);
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          kind.channelId,
          name,
          description: description,
          importance: kind == NotificationKind.cookieExpired
              ? Importance.high
              : Importance.defaultImportance,
        ),
      );
    }
  }

  Future<bool> isEnabled() async {
    await initialize();
    if (_android case final android?) {
      return await android.areNotificationsEnabled() ?? false;
    }
    if (_ios case final ios?) {
      return (await ios.checkPermissions())?.isEnabled ?? false;
    }
    return false;
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (_android case final android?) {
      return await android.requestNotificationsPermission() ?? false;
    }
    if (_ios case final ios?) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  Future<void> openSystemSettings() async {
    await initialize();
    await _plugin.openAppNotificationSettings();
  }

  static (String, String) _channelText(
    NotificationKind kind,
    AppLocalizations l10n,
  ) => switch (kind) {
    NotificationKind.stamina => (
      l10n.notificationChannelStamina,
      l10n.notificationChannelStaminaDescription,
    ),
    NotificationKind.expeditions => (
      l10n.notificationChannelExpeditions,
      l10n.notificationChannelExpeditionsDescription,
    ),
    NotificationKind.currency => (
      l10n.notificationChannelCurrency,
      l10n.notificationChannelCurrencyDescription,
    ),
    NotificationKind.transformer => (
      l10n.notificationChannelTransformer,
      l10n.notificationChannelTransformerDescription,
    ),
    NotificationKind.dailyReminder => (
      l10n.notificationChannelDailyReminder,
      l10n.notificationChannelDailyReminderDescription,
    ),
    NotificationKind.checkInResult => (
      l10n.notificationChannelCheckIn,
      l10n.notificationChannelCheckInDescription,
    ),
    NotificationKind.cookieExpired => (
      l10n.notificationChannelCookieExpired,
      l10n.notificationChannelCookieExpiredDescription,
    ),
  };
}

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) =>
    NotificationService(FlutterLocalNotificationsPlugin());
