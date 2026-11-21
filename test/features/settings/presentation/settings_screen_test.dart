import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/app_settings_provider.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/components/app_swatch_picker.dart';
import 'package:hoyo_aio/core/design_system/components/app_toggle.dart';
import 'package:hoyo_aio/features/accounts/domain/account_summary.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_settings.dart';
import 'package:hoyo_aio/features/settings/presentation/profile_card.dart';
import 'package:hoyo_aio/features/settings/presentation/settings_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../_support/settings_support.dart';

AppSwatchPicker<AppAccent> _picker(WidgetTester tester) =>
    tester.widget(find.byType(AppSwatchPicker<AppAccent>));

void main() {
  Future<void> pumpSettings(
    WidgetTester tester, {
    FakeSettingsActions? actions,
    bool dynamicSupported = false,
    bool dynamicColor = false,
    NotificationSettings notifications = const NotificationSettings(),
    List<AccountSummary>? accounts,
  }) => pumpRouted(
    tester,
    settingsRouter(const SettingsScreen()),
    overrides: settingsOverrides(
      actions: actions,
      dynamicSupported: dynamicSupported,
      notifications: notifications,
      accounts: accounts,
      preferences: AppPreferences(
        themeMode: ThemeMode.system,
        locale: null,
        onboardingSeen: true,
        dynamicColor: dynamicColor,
      ),
    ),
  );

  testWidgets('profile card shows the selected account and counts', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(
      find.descendant(
        of: find.byType(ProfileCard),
        matching: find.text('Lumine'),
      ),
      findsOneWidget,
    );
    expect(find.text('L'), findsOneWidget);
    expect(find.text('2 accounts · 3 game roles'), findsOneWidget);

    await tester.tap(find.byType(ProfileCard));
    await tester.pumpAndSettle();

    expect(find.text('route ${AppRoutes.accounts}'), findsOneWidget);
    await drainTimers(tester);
  });

  testWidgets('no profile card without accounts', (tester) async {
    await pumpSettings(tester, accounts: const []);

    expect(find.byType(ProfileCard), findsNothing);
    await drainTimers(tester);
  });

  testWidgets('theme segment writes the chosen theme', (tester) async {
    final actions = FakeSettingsActions();
    await pumpSettings(tester, actions: actions);

    await tester.tap(find.text('Dark'));
    await tester.pump();

    expect(actions.calls, ['theme:dark']);
    await drainTimers(tester);
  });

  testWidgets('accent swatch writes the accent', (tester) async {
    final actions = FakeSettingsActions();
    await pumpSettings(tester, actions: actions);

    await tester.tap(
      find
          .descendant(
            of: find.byType(AppSwatchPicker<AppAccent>),
            matching: find.byType(GestureDetector),
          )
          .last,
    );
    await tester.pump();

    expect(actions.calls, ['accent:neutral']);
    await drainTimers(tester);
  });

  testWidgets('dynamic color row is hidden when not supported', (tester) async {
    await pumpSettings(tester);

    expect(find.text('Dynamic Color'), findsNothing);
    expect(_picker(tester).onChanged, isNotNull);
    await drainTimers(tester);
  });

  testWidgets('dynamic color on disables swatches and toggles off', (
    tester,
  ) async {
    final actions = FakeSettingsActions();
    await pumpSettings(
      tester,
      actions: actions,
      dynamicSupported: true,
      dynamicColor: true,
    );

    expect(find.text('Dynamic Color'), findsOneWidget);
    expect(_picker(tester).onChanged, isNull);

    await tester.tap(find.byType(AppToggle));
    await tester.pump();

    expect(actions.calls, ['dynamic:false']);
    await drainTimers(tester);
  });

  testWidgets('supported but off keeps swatches enabled', (tester) async {
    await pumpSettings(tester, dynamicSupported: true);

    expect(find.text('Dynamic Color'), findsOneWidget);
    expect(_picker(tester).onChanged, isNotNull);
    await drainTimers(tester);
  });

  testWidgets('language sheet writes id and System writes null', (
    tester,
  ) async {
    final actions = FakeSettingsActions();
    await pumpSettings(tester, actions: actions);

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bahasa Indonesia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('System').last);
    await tester.pumpAndSettle();

    expect(actions.calls, ['locale:id', 'locale:null']);
    expect(find.text('Bahasa Indonesia'), findsNothing);
    await drainTimers(tester);
  });

  testWidgets('general rows show notification count and attention', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(find.text('8 on'), findsOneWidget);
    expect(find.text('1 needs attention'), findsOneWidget);
    expect(find.text('Backup'), findsOneWidget);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    expect(find.text('route ${AppRoutes.notifications}'), findsOneWidget);
    await drainTimers(tester);
  });

  testWidgets('notifications row shows Off when disabled', (tester) async {
    await pumpSettings(
      tester,
      notifications: const NotificationSettings(enabled: false),
    );

    expect(find.text('Off'), findsOneWidget);
    await drainTimers(tester);
  });

  testWidgets('accounts row opens accounts', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Accounts'));
    await tester.pumpAndSettle();

    expect(find.text('route ${AppRoutes.accounts}'), findsOneWidget);
    await drainTimers(tester);
  });

  testWidgets('about row opens about', (tester) async {
    await pumpSettings(tester);

    await tester.ensureVisible(find.text('Disclaimer & Licenses'));
    await tester.tap(find.text('Disclaimer & Licenses'));
    await tester.pumpAndSettle();

    expect(find.text('route ${AppRoutes.about}'), findsOneWidget);
    await drainTimers(tester);
  });

  testWidgets('footer shows the app version', (tester) async {
    await pumpSettings(tester);

    expect(find.textContaining('HoYo AIO 1.0.0 (1) · '), findsOneWidget);
    await drainTimers(tester);
  });
}
