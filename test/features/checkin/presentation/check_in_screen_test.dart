import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/reward_day_cell.dart';
import 'package:hoyo_aio/core/design_system/components/skeleton.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/game_labels.dart';
import 'package:hoyo_aio/features/accounts/domain/account_summary.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_month.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_record.dart';
import 'package:hoyo_aio/features/checkin/presentation/check_in_screen.dart';
import 'package:hoyo_aio/features/dashboard/presentation/states/dashboard_error.dart';
import 'package:material_ui/material_ui.dart';

import '../_support/check_in_screen_overrides.dart';
import '../_support/fake_check_in_repositories.dart';
import '../_support/pump_app.dart';

final _l10n = l10nEn;

Future<void> _pumpScreen(
  WidgetTester tester, {
  List<AccountSummary>? accounts,
  FakeCheckInRepository? checkIn,
  FakeCheckInHistoryRepository? history,
  Flavor flavor = Flavor.prod,
}) async {
  tester.view
    ..physicalSize = const Size(420, 4000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await pumpApp(
    tester,
    const CheckInScreen(),
    overrides: checkInScreenOverrides(
      accounts:
          accounts ??
          [
            testAccount([testRole(1, Game.genshin)]),
          ],
      checkIn: checkIn ?? FakeCheckInRepository(),
      history: history ?? FakeCheckInHistoryRepository(),
      flavor: flavor,
    ),
  );
  await tester.pump();
  await tester.pump();
}

RewardDayState _cellState(WidgetTester tester, int day) => tester
    .widget<RewardDayCell>(
      find.byWidgetPredicate((w) => w is RewardDayCell && w.day == day),
    )
    .state;

void _screenTest(String name, Future<void> Function(WidgetTester) body) =>
    testWidgets(name, (tester) async {
      await body(tester);
      await settleAnimations(tester);
    });

void main() {
  _screenTest('shows a hint when there are no roles', (tester) async {
    await _pumpScreen(tester, accounts: const []);

    expect(find.text(_l10n.checkInNoRoles), findsOneWidget);
  });

  _screenTest('shows a skeleton while the month loads', (tester) async {
    final pending = Completer<CheckInMonth>();
    await _pumpScreen(
      tester,
      checkIn: FakeCheckInRepository(month: (_, _) => pending.future),
    );

    expect(find.byType(Skeleton), findsOneWidget);
  });

  _screenTest('shows the error state when the month fails', (tester) async {
    await _pumpScreen(
      tester,
      checkIn: FakeCheckInRepository(
        month: (_, _) => throw const NetworkException(),
      ),
    );

    expect(find.byType(DashboardError), findsOneWidget);
  });

  _screenTest('renders the today card and every cell state', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('Thu, 5 Nov'), findsOneWidget);
    expect(find.text(_l10n.checkInNow), findsOneWidget);
    expect(find.text('Mora ×5000'), findsOneWidget);
    expect(find.textContaining('Auto run at'), findsOneWidget);
    expect(find.byType(RewardDayCell), findsNWidgets(30));
    expect(_cellState(tester, 1), RewardDayState.claimed);
    expect(_cellState(tester, 3), RewardDayState.claimed);
    expect(_cellState(tester, 4), RewardDayState.missed);
    expect(_cellState(tester, 5), RewardDayState.today);
    expect(_cellState(tester, 6), RewardDayState.upcoming);
    expect(find.text(_l10n.checkInMonthSummary(3, 1)), findsOneWidget);
    expect(find.text(_l10n.checkInHistoryEmpty), findsOneWidget);
    expect(find.text(_l10n.checkInRunNow), findsNothing);
  });

  _screenTest('uses award history dates for claimed cells', (tester) async {
    await _pumpScreen(
      tester,
      checkIn: FakeCheckInRepository(
        month: (_, game) => sampleMonth(
          game,
          signedDays: 2,
          claimedOn: {
            2: const CheckInReward(day: 2, name: 'Primogem', count: 20),
            4: const CheckInReward(day: 4, name: 'Mora', count: 5000),
          },
        ),
      ),
    );

    expect(_cellState(tester, 1), RewardDayState.missed);
    expect(_cellState(tester, 2), RewardDayState.claimed);
    expect(_cellState(tester, 3), RewardDayState.missed);
    expect(_cellState(tester, 4), RewardDayState.claimed);
  });

  _screenTest('shows Checked In and hides the auto line when signed', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      checkIn: FakeCheckInRepository(
        month: (_, game) => sampleMonth(game, signedToday: true),
      ),
    );

    expect(find.text(_l10n.checkInDone), findsOneWidget);
    expect(find.text(_l10n.checkInNow), findsNothing);
    expect(find.textContaining('Auto run at'), findsNothing);
    expect(_cellState(tester, 5), RewardDayState.claimed);
  });

  _screenTest('claiming shows a snackbar and the checked-in badge', (
    tester,
  ) async {
    var signed = false;
    final claim = Completer<ClaimOutcome>();
    await _pumpScreen(
      tester,
      checkIn: FakeCheckInRepository(
        month: (_, game) => sampleMonth(game, signedToday: signed),
        claim: (_, _) => claim.future,
      ),
    );

    await tester.tap(find.text(_l10n.checkInNow));
    await tester.pump();
    final loading = tester.widget<AppButton>(
      find.widgetWithText(AppButton, _l10n.checkInNow),
    );
    signed = true;
    claim.complete(ClaimOutcome.claimed);
    await tester.pump();
    await tester.pump();

    expect(loading.isLoading, isTrue);
    expect(find.text(_l10n.checkInClaimed('Mora ×5000')), findsOneWidget);
    expect(find.text(_l10n.checkInDone), findsOneWidget);
  });

  final outcomes = <(ClaimOutcome, String)>[
    (ClaimOutcome.alreadyClaimed, _l10n.checkInAlreadyClaimed),
    (ClaimOutcome.captcha, _l10n.checkInCaptcha),
  ];
  for (final (outcome, message) in outcomes) {
    _screenTest('claim outcome ${outcome.name} shows its message', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        checkIn: FakeCheckInRepository(claim: (_, _) => outcome),
      );

      await tester.tap(find.text(_l10n.checkInNow));
      await tester.pump();
      await tester.pump();

      expect(find.text(message), findsOneWidget);
      if (outcome == ClaimOutcome.captcha) {
        expect(find.text(_l10n.dashboardOpenHoyolab), findsOneWidget);
      }
    });
  }

  _screenTest('claim errors show the mapped error message', (tester) async {
    await _pumpScreen(
      tester,
      checkIn: FakeCheckInRepository(
        claim: (_, _) => throw const CookieExpiredException(),
      ),
    );

    await tester.tap(find.text(_l10n.checkInNow));
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(_l10n.checkInNow), findsOneWidget);
  });

  _screenTest('game chips switch the calendar', (tester) async {
    final checkIn = FakeCheckInRepository();
    await _pumpScreen(
      tester,
      accounts: [
        testAccount([testRole(1, Game.genshin), testRole(2, Game.hi3)]),
      ],
      checkIn: checkIn,
    );

    await tester.tap(find.text(_l10n.gameShortName(Game.hi3)));
    await tester.pump();
    await tester.pump();

    expect(checkIn.calls, contains('month:800000001:hi3'));
  });

  _screenTest('auto check-in toggles and run time update settings', (
    tester,
  ) async {
    final history = FakeCheckInHistoryRepository();
    await _pumpScreen(tester, history: history);

    expect(find.text(_l10n.checkInNextRunToday('09:00')), findsOneWidget);
    await tester.tap(
      find.bySemanticsLabel(
        _l10n.checkInAutoToggleSemantics(_l10n.gameName(Game.genshin)),
      ),
    );
    await tester.pumpAndSettle();
    expect(history.current.games, isEmpty);
    expect(find.text(_l10n.checkInAutoOff), findsOneWidget);

    await tester.tap(
      find.bySemanticsLabel(_l10n.checkInRunTimeSemantics('09:00')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(history.current.runAtMinutes, 9 * 60);
  });

  _screenTest('Run Now in the dev flavor runs and reports', (tester) async {
    final history = FakeCheckInHistoryRepository();
    await _pumpScreen(tester, history: history, flavor: Flavor.dev);

    await tester.tap(find.text(_l10n.checkInRunNow));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(history.added, hasLength(1));
    expect(find.text(_l10n.checkInRunDone(1, 1)), findsOneWidget);
  });

  _screenTest('history lists runs with rewards and failures', (tester) async {
    final runAt = DateTime(2026, 11, 4, 9);
    CheckInRecord record(Game game, CheckInResult result, [String? reward]) =>
        CheckInRecord(
          accountId: '800000001',
          game: game,
          day: '2026-11-04',
          result: result,
          runAt: runAt,
          reward: reward,
        );
    await _pumpScreen(
      tester,
      history: FakeCheckInHistoryRepository(
        runs: [
          for (final result in [
            CheckInResult.captcha,
            CheckInResult.cookieExpired,
            CheckInResult.noRole,
            CheckInResult.failed,
          ])
            CheckInRun(
              runAt: runAt,
              records: [
                record(Game.genshin, CheckInResult.claimed, 'Primogem ×20'),
                record(Game.zzz, result),
              ],
            ),
        ],
      ),
    );

    expect(find.text('1/2'), findsNWidgets(4));
    expect(
      find.text(
        'Primogem ×20 · ${_l10n.checkInHistoryFailure(_l10n.gameShortName(Game.zzz), _l10n.checkInResultCaptcha)}',
      ),
      findsOneWidget,
    );
    for (final reason in [
      _l10n.checkInResultCookieExpired,
      _l10n.checkInResultNoRole,
      _l10n.checkInResultFailed,
    ]) {
      expect(find.textContaining(reason), findsOneWidget);
    }
  });
}
