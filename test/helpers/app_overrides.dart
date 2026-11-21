import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:hoyo_aio/app/app_settings_provider.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/app/flavor_provider.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/has_accounts_provider.dart';
import 'package:hoyo_aio/features/background/presentation/providers/background_sync_provider.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/providers/widget_sync_provider.dart';
import 'package:hoyo_aio/features/notifications/data/notification_service.dart';
import 'package:hoyo_aio/features/notifications/presentation/providers/notification_sync_provider.dart';
import 'package:material_ui/material_ui.dart';

List<Override> appOverrides({
  required Flavor flavor,
  bool hasAccounts = false,
  bool onboardingSeen = true,
}) => [
  flavorProvider.overrideWithValue(flavor),
  notificationServiceProvider.overrideWithValue(FakeNotificationService()),
  notificationSyncProvider.overrideWith((_) async => 0),
  backgroundSyncProvider.overrideWith((_) async {}),
  widgetSyncProvider.overrideWith((_) async => null),
  hasAccountsProvider.overrideWith((_) => Stream.value(hasAccounts)),
  accountsProvider.overrideWith((_) => Stream.value(const [])),
  appPreferencesProvider.overrideWith(
    (_) => Stream.value(
      AppPreferences(
        themeMode: ThemeMode.system,
        locale: null,
        onboardingSeen: onboardingSeen,
      ),
    ),
  ),
];

Widget withAppScope(
  Widget child, {
  required Flavor flavor,
  bool hasAccounts = false,
}) => ProviderScope(
  overrides: appOverrides(flavor: flavor, hasAccounts: hasAccounts),
  child: child,
);

class FakeNotificationService extends NotificationService {
  FakeNotificationService({this.enabled = true})
    : super(FlutterLocalNotificationsPlugin());

  bool enabled;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> syncChannels(AppLocalizations l10n) async {}

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<bool> requestPermission() async => enabled = true;

  @override
  Future<void> openSystemSettings() async {}

  @override
  Future<String?> launchPayload() async => null;
}
