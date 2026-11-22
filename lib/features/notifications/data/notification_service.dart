import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/notifications/data/notification_log_repository_impl.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_kind.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_log_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart' as tz;

part 'notification_service.g.dart';

class ScheduledMessage {
  const ScheduledMessage({
    required this.id,
    required this.kind,
    required this.at,
    required this.title,
    required this.body,
    this.payload,
  });

  final int id;
  final NotificationKind kind;
  final DateTime at;
  final String title;
  final String body;
  final String? payload;
}

class NotificationService {
  NotificationService(this._plugin, [this._log]);

  static const androidIcon = 'ic_notification';

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationLogRepository? _log;
  final _taps = StreamController<String?>.broadcast();
  Future<void>? _initialized;

  Stream<String?> get taps => _taps.stream;

  Future<String?> launchPayload() async {
    await initialize();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (!(details?.didNotificationLaunchApp ?? false)) return null;
    return details?.notificationResponse?.payload;
  }

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
    onDidReceiveNotificationResponse: (response) => _taps.add(response.payload),
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

  Future<void> replaceScheduled(List<ScheduledMessage> messages) async {
    await initialize();
    for (final pending in await _plugin.pendingNotificationRequests()) {
      await _plugin.cancel(id: pending.id);
    }
    for (final message in messages) {
      await _plugin.zonedSchedule(
        id: message.id,
        scheduledDate: tz.TZDateTime.from(message.at.toUtc(), tz.UTC),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            message.kind.channelId,
            message.kind.name,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: message.title,
        body: message.body,
        payload: message.payload,
      );
    }
    await _log?.replaceUpcoming([
      for (final message in messages)
        NotificationLogEntry(
          kind: message.kind,
          title: message.title,
          body: message.body,
          payload: message.payload,
          at: message.at,
        ),
    ]);
  }

  Future<void> showNow({
    required int id,
    required NotificationKind kind,
    required String title,
    required String body,
    String? payload,
    List<(String, String)> actions = const [],
  }) async {
    await initialize();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          kind.channelId,
          kind.name,
          actions: [
            for (final (actionId, label) in actions)
              AndroidNotificationAction(
                actionId,
                label,
                showsUserInterface: true,
              ),
          ],
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
    await _log?.recordSent(
      NotificationLogEntry(
        kind: kind,
        title: title,
        body: body,
        payload: payload,
        at: DateTime.now(),
      ),
    );
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
    NotificationKind.newCodes => (
      l10n.notificationChannelNewCodes,
      l10n.notificationChannelNewCodesDescription,
    ),
    NotificationKind.newEvents => (
      l10n.notificationChannelNewEvents,
      l10n.notificationChannelNewEventsDescription,
    ),
    NotificationKind.eventEnding => (
      l10n.notificationChannelEventEnding,
      l10n.notificationChannelEventEndingDescription,
    ),
  };
}

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) => NotificationService(
  FlutterLocalNotificationsPlugin(),
  ref.watch(notificationLogRepositoryProvider),
);
