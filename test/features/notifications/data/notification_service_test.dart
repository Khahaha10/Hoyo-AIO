import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/notifications/data/notification_service.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_kind.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/timezone.dart' as tz;

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _MockAndroid extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class _MockIos extends Mock implements IOSFlutterLocalNotificationsPlugin {}

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  late _MockPlugin plugin;
  late _MockAndroid android;
  late _MockIos ios;
  late NotificationService service;

  setUpAll(() {
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const AndroidNotificationChannel('id', 'name'));
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(tz.TZDateTime.utc(2026));
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
  });

  void platform({bool isAndroid = true, bool isIos = false}) {
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(isAndroid ? android : null);
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(isIos ? ios : null);
  }

  setUp(() {
    plugin = _MockPlugin();
    android = _MockAndroid();
    ios = _MockIos();
    service = NotificationService(plugin);
    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async => true);
    platform();
  });

  test('initialize runs the plugin setup only once', () async {
    await service.initialize();
    await service.initialize();

    verify(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
      ),
    ).called(1);
  });

  test('taps forward the payload of a tapped notification', () async {
    await service.initialize();
    final callback =
        verify(
              () => plugin.initialize(
                settings: any(named: 'settings'),
                onDidReceiveNotificationResponse: captureAny(
                  named: 'onDidReceiveNotificationResponse',
                ),
              ),
            ).captured.single
            as DidReceiveNotificationResponseCallback;
    final next = service.taps.first;

    callback(
      const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'hoyoaio://dashboard?game=genshin',
      ),
    );

    expect(await next, 'hoyoaio://dashboard?game=genshin');
  });

  group('syncChannels', () {
    test('creates one localized channel per kind on Android', () async {
      when(
        () => android.createNotificationChannel(any()),
      ).thenAnswer((_) async {});

      await service.syncChannels(_en);

      final channels = verify(
        () => android.createNotificationChannel(captureAny()),
      ).captured.cast<AndroidNotificationChannel>();
      expect(
        channels.map((c) => c.id),
        NotificationKind.values.map((k) => k.channelId),
      );
      expect(channels.every((c) => c.name.isNotEmpty), isTrue);
      expect(channels.every((c) => c.description?.isNotEmpty ?? false), isTrue);
      expect(channels.first.name, _en.notificationChannelStamina);
      final cookie = channels.firstWhere(
        (c) => c.id == NotificationKind.cookieExpired.channelId,
      );
      expect(cookie.importance, Importance.high);
      expect(channels.first.importance, Importance.defaultImportance);
    });

    test('does nothing off Android', () async {
      platform(isAndroid: false, isIos: true);

      await service.syncChannels(_en);

      verifyZeroInteractions(android);
    });
  });

  group('permissions', () {
    test('Android reports and requests notification permission', () async {
      when(() => android.areNotificationsEnabled()).thenAnswer((_) async => false);
      when(
        () => android.requestNotificationsPermission(),
      ).thenAnswer((_) async => true);

      expect(await service.isEnabled(), isFalse);
      expect(await service.requestPermission(), isTrue);
    });

    test('Android null answers count as denied', () async {
      when(() => android.areNotificationsEnabled()).thenAnswer((_) async => null);
      when(
        () => android.requestNotificationsPermission(),
      ).thenAnswer((_) async => null);

      expect(await service.isEnabled(), isFalse);
      expect(await service.requestPermission(), isFalse);
    });

    test('iOS checks and requests alert, badge and sound', () async {
      platform(isAndroid: false, isIos: true);
      when(() => ios.checkPermissions()).thenAnswer(
        (_) async => const NotificationsEnabledOptions(
          isEnabled: true,
          isSoundEnabled: true,
          isAlertEnabled: true,
          isBadgeEnabled: true,
          isProvisionalEnabled: false,
          isCriticalEnabled: false,
          isProvidesAppNotificationSettingsEnabled: false,
        ),
      );
      when(
        () => ios.requestPermissions(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
        ),
      ).thenAnswer((_) async => null);

      expect(await service.isEnabled(), isTrue);
      expect(await service.requestPermission(), isFalse);
      verify(
        () => ios.requestPermissions(alert: true, badge: true, sound: true),
      ).called(1);
    });

    test('other platforms report no permission', () async {
      platform(isAndroid: false);

      expect(await service.isEnabled(), isFalse);
      expect(await service.requestPermission(), isFalse);
    });
  });

  test('replaceScheduled cancels pending ones and schedules in UTC', () async {
    when(() => plugin.pendingNotificationRequests()).thenAnswer(
      (_) async => const [
        PendingNotificationRequest(7, 'old', 'old', null),
        PendingNotificationRequest(8, 'old', 'old', null),
      ],
    );
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    final at = DateTime(2026, 11, 5, 20);

    await service.replaceScheduled([
      ScheduledMessage(
        id: 1001,
        kind: NotificationKind.stamina,
        at: at,
        title: 'Title',
        body: 'Body',
        payload: 'hoyoaio://dashboard',
      ),
    ]);

    verify(() => plugin.cancel(id: 7)).called(1);
    verify(() => plugin.cancel(id: 8)).called(1);
    final captured = verify(
      () => plugin.zonedSchedule(
        id: 1001,
        scheduledDate: captureAny(named: 'scheduledDate'),
        notificationDetails: captureAny(named: 'notificationDetails'),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'Title',
        body: 'Body',
        payload: 'hoyoaio://dashboard',
      ),
    ).captured;
    final date = captured.first as tz.TZDateTime;
    final details = captured.last as NotificationDetails;
    expect(date.location, tz.UTC);
    expect(date.isAtSameMomentAs(at), isTrue);
    expect(details.android?.channelId, NotificationKind.stamina.channelId);
  });

  test('showNow shows on the kind channel with actions', () async {
    when(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
        notificationDetails: any(named: 'notificationDetails'),
      ),
    ).thenAnswer((_) async {});

    await service.showNow(
      id: 5,
      kind: NotificationKind.newCodes,
      title: 'New code',
      body: 'CODE',
      payload: 'code:genshin:CODE',
      actions: const [('copy', 'Copy'), ('redeem', 'Redeem')],
    );

    final details =
        verify(
              () => plugin.show(
                id: 5,
                title: 'New code',
                body: 'CODE',
                payload: 'code:genshin:CODE',
                notificationDetails: captureAny(named: 'notificationDetails'),
              ),
            ).captured.single
            as NotificationDetails;
    expect(details.android?.channelId, NotificationKind.newCodes.channelId);
    expect(details.android?.actions?.map((a) => a.id), ['copy', 'redeem']);
  });

  test('openSystemSettings opens the app notification settings', () async {
    when(() => plugin.openAppNotificationSettings()).thenAnswer((_) async => true);

    await service.openSystemSettings();

    verify(() => plugin.openAppNotificationSettings()).called(1);
  });

  group('launchPayload', () {
    test('returns the payload when a notification launched the app', () async {
      when(() => plugin.getNotificationAppLaunchDetails()).thenAnswer(
        (_) async => const NotificationAppLaunchDetails(
          true,
          notificationResponse: NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: 'hoyoaio://dashboard',
          ),
        ),
      );

      expect(await service.launchPayload(), 'hoyoaio://dashboard');
    });

    test('returns null for a normal launch', () async {
      when(
        () => plugin.getNotificationAppLaunchDetails(),
      ).thenAnswer((_) async => const NotificationAppLaunchDetails(false));

      expect(await service.launchPayload(), isNull);
    });
  });
}
