import 'dart:async';

import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/provider_retry.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/accounts/domain/account_summary.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:hoyo_aio/features/codes/data/codes_repository_impl.dart';
import 'package:hoyo_aio/features/dashboard/data/notes_repository_impl.dart';
import 'package:hoyo_aio/features/dashboard/domain/note_result.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_screen.dart';
import 'package:hoyo_aio/features/events/data/events_repository_impl.dart';
import 'package:hoyo_aio/features/tracker/data/gacha_repository_impl.dart';
import 'package:material_ui/material_ui.dart';

import 'dashboard_fakes.dart';

final l10nEn = lookupAppLocalizations(const Locale('en'));

class GatedNotesRepository extends FakeNotesRepository {
  Completer<NoteResult>? gate;

  @override
  Future<NoteResult> refresh(role) async {
    final pending = gate;
    if (pending == null) return super.refresh(role);
    refreshed.add(role);
    return pending.future;
  }
}

Future<void> pumpDashboard(
  WidgetTester tester, {
  required List<AccountSummary> accounts,
  required FakeNotesRepository repository,
  DateTime? now,
  bool dark = false,
  String? deepLinkGame,
  String? deepLinkRoleUid,
  bool settle = true,
}) async {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final at = now ?? fixedNow;
  Widget placeholder(String name) => Scaffold(body: Text('route:$name'));
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: DashboardScreen(
            deepLinkGame: deepLinkGame,
            deepLinkRoleUid: deepLinkRoleUid,
          ),
        ),
      ),
      GoRoute(path: AppRoutes.codes, builder: (_, _) => placeholder('codes')),
      GoRoute(path: AppRoutes.inbox, builder: (_, _) => placeholder('inbox')),
      GoRoute(
        path: AppRoutes.addAccount,
        builder: (_, _) => placeholder('addAccount'),
      ),
      GoRoute(
        path: AppRoutes.tracker,
        builder: (_, _) => placeholder('tracker'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: noProviderRetry,
      overrides: [
        accountsProvider.overrideWith((_) => Stream.value(accounts)),
        notesRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => at),
        clockTickProvider.overrideWith((_) => Stream.value(at)),
        unreadCodesProvider.overrideWithValue(2),
        unreadEventsProvider.overrideWithValue(1),
        gachaRepositoryProvider.overrideWithValue(EmptyGachaRepository()),
      ],
      child: MaterialApp.router(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
}
