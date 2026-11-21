import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/provider_retry.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/domain/account_summary.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:material_ui/material_ui.dart';

final l10nEn = lookupAppLocalizations(const Locale('en'));

SavedRole testRole(
  int id,
  Game game, {
  String accountId = '800000001',
  bool enabled = true,
}) => SavedRole(
  id: id,
  accountId: accountId,
  game: game,
  uid: '80000000$id',
  server: 'os_asia',
  nickname: 'Tester $id',
  level: 60,
  enabled: enabled,
);

AccountSummary testAccount(
  List<SavedRole> roles, {
  String id = '800000001',
  AccountStatus status = AccountStatus.valid,
}) => AccountSummary(
  id: id,
  nickname: 'Tester',
  status: status,
  updatedAt: DateTime(2026, 11),
  roles: roles,
);

Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  bool dark = false,
  bool wrapScaffold = true,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => wrapScaffold ? Scaffold(body: child) : child,
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: noProviderRetry,
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: router,
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
      ),
    ),
  );
}

Future<void> settleAnimations(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await tester.pump(const Duration(seconds: 1));
}
