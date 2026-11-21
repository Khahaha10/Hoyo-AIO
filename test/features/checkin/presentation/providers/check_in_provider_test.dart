import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/provider_retry.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/accounts/domain/account_summary.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/selected_role_provider.dart';
import 'package:hoyo_aio/features/checkin/data/check_in_history_repository_impl.dart';
import 'package:hoyo_aio/features/checkin/data/check_in_repository_impl.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_month.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_record.dart';
import 'package:hoyo_aio/features/checkin/presentation/providers/check_in_provider.dart';

import '../../_support/fake_check_in_repositories.dart';
import '../../_support/pump_app.dart';

ProviderContainer _container({
  List<AccountSummary> accounts = const [],
  FakeCheckInRepository? checkIn,
  FakeCheckInHistoryRepository? history,
}) {
  final container = ProviderContainer(
    retry: noProviderRetry,
    overrides: [
      accountsProvider.overrideWith((_) => Stream.value(accounts)),
      checkInRepositoryProvider.overrideWithValue(
        checkIn ?? FakeCheckInRepository(),
      ),
      checkInHistoryRepositoryProvider.overrideWithValue(
        history ?? FakeCheckInHistoryRepository(),
      ),
      clockProvider.overrideWithValue(() => DateTime(2026, 11, 5, 10)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _loadAccounts(ProviderContainer container) async {
  container.listen(accountsProvider, (_, _) {});
  await container.read(accountsProvider.future);
}

void main() {
  test(
    'checkInRoles lists healthy accounts first and only enabled roles',
    () async {
      final container = _container(
        accounts: [
          testAccount(
            [testRole(1, Game.genshin, accountId: 'a')],
            id: 'a',
            status: AccountStatus.expired,
          ),
          testAccount([
            testRole(2, Game.hi3, accountId: 'b'),
            testRole(3, Game.zzz, accountId: 'b', enabled: false),
          ], id: 'b'),
        ],
      );
      await _loadAccounts(container);

      final roles = container.read(checkInRolesProvider);

      expect(roles.map((r) => r.id), [2, 1]);
      expect(container.read(checkInGamesProvider), [Game.genshin, Game.hi3]);
    },
  );

  test(
    'checkInRole follows the chosen game, then the dashboard game',
    () async {
      final container = _container(
        accounts: [
          testAccount([
            testRole(1, Game.genshin),
            testRole(2, Game.starRail),
            testRole(3, Game.hi3),
          ]),
        ],
      );
      await _loadAccounts(container);

      container.read(selectedRoleIdProvider.notifier).select(2);
      final fromDashboard = container.read(checkInRoleProvider);
      container.read(checkInSelectedGameProvider.notifier).select(Game.hi3);
      final chosen = container.read(checkInRoleProvider);

      expect(fromDashboard?.id, 2);
      expect(chosen?.id, 3);
    },
  );

  test('checkInRole prefers the dashboard account for the game', () async {
    final container = _container(
      accounts: [
        testAccount([testRole(1, Game.genshin, accountId: 'a')], id: 'a'),
        testAccount([testRole(2, Game.genshin, accountId: 'b')], id: 'b'),
      ],
    );
    await _loadAccounts(container);

    container.read(selectedRoleIdProvider.notifier).select(2);

    expect(container.read(checkInRoleProvider)?.id, 2);
  });

  test('checkInRole is null without roles', () {
    final container = _container();

    expect(container.read(checkInRoleProvider), isNull);
  });

  test('checkInCalendar loads, refreshes and claims', () async {
    var signed = false;
    final checkIn = FakeCheckInRepository(
      month: (_, game) => sampleMonth(game, signedToday: signed),
      claim: (_, _) {
        signed = true;
        return ClaimOutcome.claimed;
      },
    );
    final container = _container(checkIn: checkIn);
    final provider = checkInCalendarProvider('800000001', Game.genshin);
    container.listen(provider, (_, _) {});

    final first = await container.read(provider.future);
    final outcome = await container.read(provider.notifier).claim();

    expect(first.signedToday, isFalse);
    expect(outcome, ClaimOutcome.claimed);
    expect(container.read(provider).value?.signedToday, isTrue);
    expect(checkIn.calls.where((c) => c.startsWith('month')), hasLength(2));
  });

  test('checkInCalendar claim does not reload after a captcha', () async {
    final checkIn = FakeCheckInRepository(
      claim: (_, _) => ClaimOutcome.captcha,
    );
    final container = _container(checkIn: checkIn);
    final provider = checkInCalendarProvider('800000001', Game.zzz);
    container.listen(provider, (_, _) {});
    await container.read(provider.future);

    final outcome = await container.read(provider.notifier).claim();

    expect(outcome, ClaimOutcome.captcha);
    expect(checkIn.calls.where((c) => c.startsWith('month')), hasLength(1));
  });

  test('checkInCalendar refresh stores errors', () async {
    var fail = false;
    final checkIn = FakeCheckInRepository(
      month: (_, game) =>
          fail ? throw const NetworkException() : sampleMonth(game),
    );
    final container = _container(checkIn: checkIn);
    final provider = checkInCalendarProvider('800000001', Game.genshin);
    container.listen(provider, (_, _) {});
    await container.read(provider.future);

    fail = true;
    await container.read(provider.notifier).refresh();

    expect(container.read(provider).error, isA<NetworkException>());
  });

  test('auto check-in settings and runs come from history', () async {
    final history = FakeCheckInHistoryRepository(
      runs: [CheckInRun(runAt: DateTime(2026, 11, 5, 9), records: const [])],
    );
    final container = _container(history: history);
    container
      ..listen(autoCheckInSettingsProvider, (_, _) {})
      ..listen(checkInRunsProvider, (_, _) {});

    final settings = await container.read(autoCheckInSettingsProvider.future);
    final runs = await container.read(checkInRunsProvider.future);

    expect(settings.games, {Game.genshin});
    expect(runs, hasLength(1));
  });

  test('runAutoCheckIn uses the injected clock', () async {
    final history = FakeCheckInHistoryRepository();
    final container = _container(history: history);

    final run = await container.read(runAutoCheckInProvider)(
      roles: [testRole(1, Game.genshin)],
      games: {Game.genshin},
    );

    expect(run.runAt, DateTime(2026, 11, 5, 10));
    expect(run.records.single.result, CheckInResult.claimed);
    expect(history.added, hasLength(1));
  });
}
