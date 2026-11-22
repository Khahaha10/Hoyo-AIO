import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/app_settings_provider.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/app/flavor_provider.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/domain/account_summary.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:hoyo_aio/features/notifications/data/notification_service.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_settings.dart';
import 'package:hoyo_aio/features/notifications/presentation/providers/notification_sync_provider.dart';
import 'package:hoyo_aio/features/settings/data/backup_service.dart';
import 'package:hoyo_aio/features/settings/domain/backup_schema.dart';
import 'package:hoyo_aio/features/settings/presentation/appearance_card.dart';
import 'package:hoyo_aio/features/settings/presentation/providers/package_info_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../helpers/app_overrides.dart';

const fakeUid = '800000001';
const otherUid = '800000002';

final testNow = DateTime.utc(2026, 11, 21, 12);

AppDatabase openSettingsDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

BackupData sampleBackup() => BackupData(
  exportedAt: testNow,
  settings: const BackupSettings(
    themeMode: AppThemeMode.dark,
    dynamicColor: true,
    accent: 'neutral',
    localeCode: 'id',
    autoCheckInMinutes: 8 * 60,
    autoCheckInGames: [Game.genshin, Game.zzz],
    notificationSettings: {'enabled': false},
    refreshIntervalMinutes: 60,
  ),
  accounts: const [
    BackupAccount(
      id: 'account-1',
      nickname: 'Traveler',
      roles: [
        BackupRole(
          game: Game.genshin,
          uid: fakeUid,
          server: 'os_asia',
          nickname: 'Traveler',
          level: 60,
          enabled: true,
        ),
      ],
    ),
  ],
  widgets: const [
    BackupWidget(
      widgetId: 7,
      size: WidgetSize.medium,
      accountId: 'account-1',
      roleGame: Game.genshin,
      roleUid: fakeUid,
      theme: WidgetTheme.dark,
      opacity: 0.5,
      accent: 'lime',
      fontSize: WidgetFontSize.large,
      visibleItems: ['resin', 'realm'],
    ),
  ],
);

SavedRole savedRole({
  required int id,
  required String accountId,
  Game game = Game.genshin,
  bool enabled = true,
}) => SavedRole(
  id: id,
  accountId: accountId,
  game: game,
  uid: fakeUid,
  server: 'os_asia',
  nickname: 'Role $id',
  level: 60,
  enabled: enabled,
);

AccountSummary accountSummary({
  required String id,
  required String nickname,
  AccountStatus status = AccountStatus.valid,
  List<SavedRole> roles = const [],
}) => AccountSummary(
  id: id,
  nickname: nickname,
  status: status,
  updatedAt: testNow,
  roles: roles,
);

final defaultAccounts = [
  accountSummary(
    id: 'a1',
    nickname: 'Aether',
    status: AccountStatus.expired,
    roles: [savedRole(id: 1, accountId: 'a1')],
  ),
  accountSummary(
    id: 'b2',
    nickname: 'Lumine',
    roles: [
      savedRole(id: 2, accountId: 'b2', game: Game.starRail),
      savedRole(id: 3, accountId: 'b2', game: Game.zzz),
      savedRole(id: 4, accountId: 'b2', enabled: false),
    ],
  ),
];

class FakeSettingsActions extends AppSettingsActions {
  final calls = <String>[];

  @override
  Future<void> setThemeMode(ThemeMode mode) async =>
      calls.add('theme:${mode.name}');

  @override
  Future<void> setAccent(AppAccent accent) async =>
      calls.add('accent:${accent.name}');

  @override
  Future<void> setDynamicColor({required bool enabled}) async =>
      calls.add('dynamic:$enabled');

  @override
  Future<void> setLocale(String? languageCode) async =>
      calls.add('locale:$languageCode');
}

class FakeBackupService implements BackupService {
  FakeBackupService({this.picked, this.pickError, this.needsLogin = 0});

  BackupData? picked;
  Object? pickError;
  int needsLogin;
  final calls = <String>[];

  @override
  Future<void> export() async => calls.add('export');

  @override
  Future<BackupData?> pick() async {
    calls.add('pick');
    if (pickError case final error?) throw error;
    return picked;
  }

  @override
  Future<BackupData> read() async => sampleBackup();

  @override
  Future<BackupImportResult> apply(BackupData data) async {
    calls.add('apply');
    return BackupImportResult(needsLogin: needsLogin);
  }
}

PackageInfo fakePackageInfo() => PackageInfo(
  appName: 'HoYo AIO',
  packageName: 'com.hoyoaio.app',
  version: '1.0.0',
  buildNumber: '1',
);

List<Override> settingsOverrides({
  List<AccountSummary>? accounts,
  AppPreferences preferences = const AppPreferences(
    themeMode: ThemeMode.system,
    locale: null,
    onboardingSeen: true,
  ),
  NotificationSettings notifications = const NotificationSettings(),
  bool dynamicSupported = false,
  FakeSettingsActions? actions,
  BackupService? backup,
}) => [
  flavorProvider.overrideWithValue(Flavor.prod),
  accountsProvider.overrideWith(
    (_) => Stream.value(accounts ?? defaultAccounts),
  ),
  appPreferencesProvider.overrideWith((_) => Stream.value(preferences)),
  notificationSettingsProvider.overrideWith((_) => Stream.value(notifications)),
  notificationServiceProvider.overrideWithValue(FakeNotificationService()),
  packageInfoProvider.overrideWith((_) async => fakePackageInfo()),
  dynamicColorSupportedProvider.overrideWith((_) async => dynamicSupported),
  appSettingsActionsProvider.overrideWith(
    () => actions ?? FakeSettingsActions(),
  ),
  backupServiceProvider.overrideWithValue(backup ?? FakeBackupService()),
];

GoRouter settingsRouter(Widget home) => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => Scaffold(body: home),
    ),
    for (final path in [
      AppRoutes.accounts,
      AppRoutes.notifications,
      AppRoutes.about,
    ])
      GoRoute(
        path: path,
        builder: (_, _) => Scaffold(body: Text('route $path')),
      ),
  ],
);

Future<void> pumpRouted(
  WidgetTester tester,
  GoRouter router, {
  required List<Override> overrides,
  bool dark = false,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = const Size(390 * 3, 1100 * 3)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> drainTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 10));
}
