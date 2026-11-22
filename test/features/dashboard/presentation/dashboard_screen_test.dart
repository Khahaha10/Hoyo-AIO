import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/game_labels.dart';
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';
import 'package:hoyo_aio/features/dashboard/domain/note_result.dart';
import 'package:hoyo_aio/features/dashboard/presentation/game_layouts/genshin_layout.dart';
import 'package:hoyo_aio/features/dashboard/presentation/game_layouts/star_rail_layout.dart';
import 'package:hoyo_aio/features/dashboard/presentation/game_layouts/zzz_layout.dart';
import 'package:hoyo_aio/features/dashboard/presentation/states/cookie_expired_banner.dart';
import 'package:hoyo_aio/features/dashboard/presentation/states/dashboard_empty.dart';
import 'package:hoyo_aio/features/dashboard/presentation/states/dashboard_error.dart';
import 'package:hoyo_aio/features/dashboard/presentation/states/dashboard_skeleton.dart';
import 'package:hoyo_aio/features/dashboard/presentation/states/refreshing_indicator.dart';
import 'package:hoyo_aio/features/tracker/presentation/tracker_labels.dart';
import 'package:material_ui/material_ui.dart';

import '../_support/dashboard_fakes.dart';
import '../_support/dashboard_harness.dart';

void main() {
  final l10n = l10nEn;
  final genshin = fakeRole(Game.genshin);
  final starRail = fakeRole(Game.starRail);
  final zzz = fakeRole(Game.zzz);

  late GatedNotesRepository repository;

  setUp(() => repository = GatedNotesRepository());

  void cacheAll({DateTime? fetchedAt}) {
    for (final role in [genshin, starRail, zzz]) {
      repository.cachedResults[role.id] = NoteResult(
        note: fixtureNote(role.game, fetchedAt: fetchedAt),
      );
    }
  }

  group('per game', () {
    testWidgets('shows the Genshin layout from the fixture', (tester) async {
      cacheAll();

      await pumpDashboard(
        tester,
        accounts: [fakeAccount()],
        repository: repository,
      );

      expect(find.byType(GenshinLayout), findsOneWidget);
      expect(find.text(l10n.genshinResin.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.genshinRealmCurrency), findsOneWidget);
      expect(find.text(l10n.dashboardUpdatedJustNow), findsOneWidget);
      expect(repository.refreshed, isEmpty);
    });

    testWidgets('switches to Star Rail with the game chip', (tester) async {
      cacheAll();
      await pumpDashboard(
        tester,
        accounts: [fakeAccount()],
        repository: repository,
      );

      await tester.tap(find.text(l10n.gameShortName(Game.starRail)));
      await tester.pumpAndSettle();

      expect(find.byType(StarRailLayout), findsOneWidget);
      expect(
        find.text(l10n.starRailTrailblazePower.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text(l10n.starRailDailyTraining), findsOneWidget);
    });

    testWidgets('opens ZZZ from a deep link', (tester) async {
      cacheAll();

      await pumpDashboard(
        tester,
        accounts: [fakeAccount()],
        repository: repository,
        deepLinkGame: Game.zzz.name,
        deepLinkRoleUid: zzz.uid,
      );

      expect(find.byType(ZzzLayout), findsOneWidget);
      expect(find.text(l10n.zzzBattery.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.zzzEngagement), findsOneWidget);
    });

    testWidgets('hides HI3 from the game chips', (tester) async {
      cacheAll();

      await pumpDashboard(
        tester,
        accounts: [fakeAccount()],
        repository: repository,
      );

      expect(find.text(l10n.gameShortName(Game.hi3)), findsNothing);
    });

    testWidgets('lays out other note shapes without errors', (tester) async {
      final t0 = fixedNow;
      repository
        ..cachedResults[genshin.id] = NoteResult(
          note: (fixtureNote(Game.genshin) as GenshinNote).copyWith(
            transformerReadyAt: t0.subtract(const Duration(minutes: 1)),
            commissionBonusClaimed: true,
            expeditions: const [],
          ),
        )
        ..cachedResults[zzz.id] = NoteResult(
          note: (fixtureNote(Game.zzz) as ZzzNote).copyWith(
            videoStore: VideoStoreState.revenueReady,
            scratchCardDone: false,
            bountyCommission: null,
            weeklyProgress: null,
          ),
        )
        ..cachedResults[starRail.id] = NoteResult(
          note: fixtureNote(Game.starRail),
        );

      await pumpDashboard(
        tester,
        accounts: [fakeAccount()],
        repository: repository,
        now: t0.add(const Duration(days: 2)),
      );
      expect(find.text(l10n.dashboardReady), findsOneWidget);
      expect(find.text(l10n.dashboardBonusClaimed), findsOneWidget);

      await tester.tap(find.text(l10n.gameShortName(Game.zzz)));
      await tester.pumpAndSettle();
      expect(find.text(l10n.zzzVideoStoreRevenue), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('states', () {
    testWidgets('shows the skeleton while the first load runs', (tester) async {
      repository.gate = Completer();

      await pumpDashboard(
        tester,
        accounts: [fakeAccount()],
        repository: repository,
        settle: false,
      );

      expect(find.byType(DashboardSkeleton), findsOneWidget);
      repository.gate?.complete(NoteResult(note: fixtureNote(Game.genshin)));
      await tester.pumpAndSettle();
      expect(find.byType(GenshinLayout), findsOneWidget);
    });

    testWidgets('shows the refreshing indicator over existing data', (
      tester,
    ) async {
      cacheAll();
      await pumpDashboard(
        tester,
        accounts: [fakeAccount()],
        repository: repository,
      );
      repository.gate = Completer();

      await tester.tap(find.bySemanticsLabel(l10n.dashboardRefresh));
      await tester.pump();

      expect(find.byType(RefreshingIndicator), findsOneWidget);
      expect(find.byType(GenshinLayout), findsOneWidget);
      repository.gate?.complete(NoteResult(note: fixtureNote(Game.genshin)));
      await tester.pumpAndSettle();
      expect(find.byType(RefreshingIndicator), findsNothing);
    });

    testWidgets('shows the empty state without dashboard roles', (
      tester,
    ) async {
      await pumpDashboard(
        tester,
        accounts: [
          fakeAccount(roles: [fakeRole(Game.hi3)]),
        ],
        repository: repository,
      );

      expect(find.byType(DashboardEmpty), findsOneWidget);
      expect(find.text(l10n.dashboardEmptyTitle), findsOneWidget);

      await tester.tap(find.text(l10n.addAccountTitle));
      await tester.pumpAndSettle();
      expect(find.text('route:addAccount'), findsOneWidget);
    });

    testWidgets('shows the cookie banner over stale data until Later', (
      tester,
    ) async {
      cacheAll(fetchedAt: fixedNow.subtract(const Duration(hours: 2)));

      await pumpDashboard(
        tester,
        accounts: [fakeAccount(status: AccountStatus.expired)],
        repository: repository,
      );

      expect(find.byType(CookieExpiredBanner), findsOneWidget);
      expect(find.text(l10n.dashboardCookieExpiredTitle), findsOneWidget);
      expect(
        tester.widget<GenshinLayout>(find.byType(GenshinLayout)).isStale,
        isTrue,
      );

      await tester.tap(find.text(l10n.dashboardLater));
      await tester.pumpAndSettle();
      expect(find.byType(CookieExpiredBanner), findsNothing);
    });

    testWidgets('shows the banner when a refresh reports an expired cookie', (
      tester,
    ) async {
      repository.cachedResults[genshin.id] = NoteResult(
        note: fixtureNote(Game.genshin),
        isStale: true,
        error: const CookieExpiredException(),
      );

      await pumpDashboard(
        tester,
        accounts: [fakeAccount()],
        repository: repository,
      );

      expect(find.byType(CookieExpiredBanner), findsOneWidget);
      await tester.tap(find.text(l10n.accountsRefreshCookie).first);
      await tester.pumpAndSettle();
      expect(find.text('route:addAccount'), findsOneWidget);
    });

    testWidgets('shows a network snackbar with Retry after a failed refresh', (
      tester,
    ) async {
      cacheAll();
      await pumpDashboard(
        tester,
        accounts: [fakeAccount()],
        repository: repository,
      );
      repository.refreshErrors[genshin.id] = const NetworkException();

      await tester.tap(find.bySemanticsLabel(l10n.dashboardRefresh));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(l10n.commonRetry), findsOneWidget);
      expect(find.byType(GenshinLayout), findsOneWidget);

      repository.refreshErrors.clear();
      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();
      expect(repository.refreshed, hasLength(2));
    });

    testWidgets('pull to refresh calls the repository', (tester) async {
      cacheAll();
      await pumpDashboard(
        tester,
        accounts: [fakeAccount()],
        repository: repository,
      );

      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(repository.refreshed, [genshin]);
    });

    final errorCases = <(String, Object, String)>[
      ('Retry', const NetworkException(), 'commonRetry'),
      ('Refresh Cookie', const CookieExpiredException(), 'refresh'),
      ('Open HoYoLAB', const CaptchaRequiredException(), 'open'),
    ];
    for (final (name, error, kind) in errorCases) {
      testWidgets('shows a full error with $name without cached data', (
        tester,
      ) async {
        repository.refreshErrors[genshin.id] = error;

        await pumpDashboard(
          tester,
          accounts: [fakeAccount()],
          repository: repository,
        );

        expect(find.byType(DashboardError), findsOneWidget);
        final label = switch (kind) {
          'refresh' => l10n.accountsRefreshCookie,
          'open' => l10n.dashboardOpenHoyolab,
          _ => l10n.commonRetry,
        };
        expect(find.text(label), findsOneWidget);
        if (kind == 'commonRetry') {
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
          expect(repository.refreshed, hasLength(2));
        }
      });
    }
  });

  group('header', () {
    testWidgets('switches role from the sheet when several exist', (
      tester,
    ) async {
      final other = fakeRole(Game.genshin, id: 50, accountId: '800000002');
      cacheAll();
      repository.cachedResults[other.id] = NoteResult(
        note: fixtureNote(Game.genshin),
      );
      await pumpDashboard(
        tester,
        accounts: [
          fakeAccount(),
          fakeAccount(
            id: '800000002',
            nickname: 'Second',
            roles: [other.copyWith(nickname: 'Alt')],
          ),
        ],
        repository: repository,
      );

      await tester.tap(find.text('Traveler'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.dashboardSwitchRole), findsOneWidget);
      await tester.tap(find.text('Alt · ${l10n.gameShortName(Game.genshin)}'));
      await tester.pumpAndSettle();

      expect(find.text('Alt'), findsOneWidget);
    });

    testWidgets('opens the notification log from the bell', (tester) async {
      cacheAll();
      await pumpDashboard(
        tester,
        accounts: [fakeAccount()],
        repository: repository,
      );

      await tester.tap(find.bySemanticsLabel(RegExp(l10n.inboxTitle)).first);
      await tester.pumpAndSettle();

      expect(find.text('route:inbox'), findsOneWidget);
    });

    testWidgets('opens the tracker from the shortcut row', (tester) async {
      cacheAll();
      await pumpDashboard(
        tester,
        accounts: [fakeAccount()],
        repository: repository,
      );

      await tester.tap(find.text(l10n.trackerChip(Game.genshin)));
      await tester.pumpAndSettle();

      expect(find.text('route:tracker'), findsOneWidget);
    });
  });
}
