import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/design_system/components/app_slider.dart';
import 'package:hoyo_aio/core/design_system/components/app_toggle.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/platform/system_settings.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:hoyo_aio/features/background/data/background_settings_repository_impl.dart';
import 'package:hoyo_aio/features/dashboard/data/notes_repository_impl.dart';
import 'package:hoyo_aio/features/dashboard/domain/note_result.dart';
import 'package:hoyo_aio/features/dashboard/domain/notes_repository.dart';
import 'package:hoyo_aio/features/notifications/data/notification_service.dart';
import 'package:hoyo_aio/features/notifications/data/notification_settings_repository_impl.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_settings.dart';
import 'package:hoyo_aio/features/notifications/presentation/notification_permission_banner.dart';
import 'package:hoyo_aio/features/notifications/presentation/notifications_screen.dart';
import 'package:hoyo_aio/features/notifications/presentation/widgets/stamina_threshold_row.dart';
import 'package:material_ui/material_ui.dart';

import '../../checkin/_support/pump_app.dart';
import '../_support/fake_settings_repository.dart';
import '../_support/notes.dart';
import '../_support/recording_notification_service.dart';

final _l10n = l10nEn;

class _Notes implements NotesRepository {
  @override
  Future<NoteResult?> cached(SavedRole role) async =>
      NoteResult(note: genshinNote());

  @override
  Future<NoteResult> refresh(SavedRole role) async =>
      NoteResult(note: genshinNote());
}

Future<(FakeNotificationSettingsRepository, RecordingNotificationService)>
_pump(
  WidgetTester tester, {
  NotificationSettings settings = const NotificationSettings(),
  bool permission = true,
  bool withRole = false,
}) async {
  tester.view
    ..physicalSize = const Size(420, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repository = FakeNotificationSettingsRepository(settings);
  final service = RecordingNotificationService(enabled: permission);
  await pumpApp(
    tester,
    const NotificationsScreen(),
    wrapScaffold: false,
    overrides: [
      notificationSettingsRepositoryProvider.overrideWithValue(repository),
      notificationServiceProvider.overrideWithValue(service),
      accountsProvider.overrideWith(
        (_) => Stream.value([
          if (withRole) testAccount([testRole(1, Game.genshin)]),
        ]),
      ),
      notesRepositoryProvider.overrideWithValue(_Notes()),
      refreshMinutesProvider.overrideWith((_) => const Stream.empty()),
      batteryOptimizationIgnoredProvider.overrideWith((_) async => true),
      clockTickProvider.overrideWith(
        (ref) => Stream.value(ref.watch(clockProvider)()),
      ),
    ],
  );
  await tester.pump();
  await tester.pump();
  return (repository, service);
}

Finder get _bannerAllow => find.descendant(
  of: find.byType(NotificationPermissionBanner),
  matching: find.text(_l10n.notificationPermissionAllow),
);

Finder _toggle(String label) =>
    find.byWidgetPredicate((w) => w is AppToggle && w.semanticLabel == label);

void main() {
  testWidgets('shows every alert row with the locked cookie row', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text(_l10n.notificationsTitle), findsOneWidget);
    expect(find.byType(StaminaThresholdRow), findsOneWidget);
    expect(find.text(_l10n.notificationsThresholdPercent(90)), findsOneWidget);
    final cookie = tester.widget<AppToggle>(
      _toggle(_l10n.notificationsCookieExpired),
    );
    expect(cookie.value, isTrue);
    expect(cookie.onChanged, isNull);
    expect(find.text(_l10n.notificationPermissionBody), findsNothing);
  });

  testWidgets('alert toggles save the new settings', (tester) async {
    final (repository, _) = await _pump(tester);
    final labels = {
      _l10n.notificationsExpeditions: (NotificationSettings s) => s.expeditions,
      _l10n.notificationsCurrency: (NotificationSettings s) => s.currency,
      _l10n.notificationsTransformer: (NotificationSettings s) => s.transformer,
      _l10n.notificationsCheckIn: (NotificationSettings s) => s.checkInResult,
      _l10n.notificationsCodes: (NotificationSettings s) => s.codes,
      _l10n.notificationsEvents: (NotificationSettings s) => s.events,
    };

    for (final MapEntry(key: label, value: read) in labels.entries) {
      await tester.tap(_toggle(label));
      await tester.pumpAndSettle();
      expect(read(repository.current), isFalse, reason: label);
    }
    await tester.tap(_toggle(_l10n.notificationsDailyReminder));
    await tester.pumpAndSettle();
    expect(repository.current.dailyReminder, isTrue);
  });

  testWidgets('turning stamina off hides the threshold slider', (tester) async {
    final (repository, _) = await _pump(tester);

    await tester.tap(_toggle(_l10n.notificationsStamina));
    await tester.pumpAndSettle();

    expect(repository.current.stamina, isFalse);
    expect(find.byType(StaminaThresholdRow), findsNothing);
  });

  testWidgets('the threshold slider saves in five percent steps', (
    tester,
  ) async {
    final (repository, _) = await _pump(tester);

    await tester.drag(find.byType(Slider), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(repository.current.staminaThresholdPercent, 50);
    expect(repository.current.staminaThresholdPercent % 5, 0);
  });

  testWidgets('the threshold shows the stamina value of the selected role', (
    tester,
  ) async {
    await _pump(tester, withRole: true);
    await tester.pump();

    expect(
      find.text(
        _l10n.notificationsThresholdValue(90, 180, 200, _l10n.genshinResin),
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 10));
  });

  testWidgets('master toggle off disables the alert controls', (tester) async {
    final (repository, _) = await _pump(
      tester,
      settings: const NotificationSettings(enabled: false),
    );

    expect(
      tester.widget<AppToggle>(_toggle(_l10n.notificationsStamina)).onChanged,
      isNull,
    );
    expect(
      tester
          .widget<AppToggle>(_toggle(_l10n.notificationsQuietHours))
          .onChanged,
      isNull,
    );
    expect(tester.widget<AppSlider>(find.byType(AppSlider)).onChanged, isNull);
    expect(repository.saved, isEmpty);
  });

  testWidgets('master toggle on saves and asks for permission', (tester) async {
    final (repository, service) = await _pump(
      tester,
      settings: const NotificationSettings(enabled: false),
      permission: false,
    );

    await tester.tap(_toggle(_l10n.notificationsAllow));
    await tester.pumpAndSettle();

    expect(repository.current.enabled, isTrue);
    expect(service.permissionRequests, 1);
  });

  testWidgets('quiet hours toggle and range picker save', (tester) async {
    final (repository, _) = await _pump(tester);

    expect(
      find.text(_l10n.notificationsQuietRange('23:00', '07:00')),
      findsOneWidget,
    );
    await tester.tap(_toggle(_l10n.notificationsQuietHours));
    await tester.pumpAndSettle();
    expect(repository.current.quietHours, isTrue);

    await tester.tap(find.text(_l10n.notificationsQuietHours));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(repository.current.quietStartMinutes, 23 * 60);
    expect(repository.current.quietEndMinutes, 7 * 60);
    expect(repository.saved, hasLength(2));
  });

  testWidgets('cancelling the quiet hours picker saves nothing', (
    tester,
  ) async {
    final (repository, _) = await _pump(tester);

    await tester.tap(find.text(_l10n.notificationsQuietHours));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.saved, isEmpty);
  });

  testWidgets('the daily reminder time pill opens a picker and saves', (
    tester,
  ) async {
    final (repository, _) = await _pump(tester);

    await tester.tap(find.text('21:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(repository.saved.single.dailyReminderMinutes, 21 * 60);
  });

  testWidgets('denied permission shows a banner that requests again', (
    tester,
  ) async {
    final (_, service) = await _pump(tester, permission: false);
    service.grant = false;

    expect(find.text(_l10n.notificationPermissionBody), findsOneWidget);
    await tester.tap(_bannerAllow);
    await tester.pumpAndSettle();

    expect(service.permissionRequests, 1);
    expect(service.settingsOpened, 1);
    expect(find.text(_l10n.notificationPermissionBody), findsOneWidget);
  });

  testWidgets('granting permission hides the banner', (tester) async {
    final (_, service) = await _pump(tester, permission: false);

    await tester.tap(_bannerAllow);
    await tester.pumpAndSettle();

    expect(service.settingsOpened, 0);
    expect(find.text(_l10n.notificationPermissionBody), findsNothing);
  });

  testWidgets('resuming the app rechecks the permission', (tester) async {
    final (_, service) = await _pump(tester, permission: false);

    service.enabled = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text(_l10n.notificationPermissionBody), findsNothing);
  });

  test('minutesLabel formats minutes of the day', () {
    expect(minutesLabel(_l10n, 7 * 60 + 5), '07:05');
  });
}
