import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/accounts/domain/account_summary.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/background/background_jobs.dart';
import 'package:hoyo_aio/features/checkin/data/check_in_history_repository_impl.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_record.dart';
import 'package:hoyo_aio/features/codes/domain/redeem_code.dart';
import 'package:hoyo_aio/features/events/domain/web_event.dart';
import 'package:hoyo_aio/features/notifications/data/notification_settings_repository_impl.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_kind.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_settings.dart';
import 'package:mocktail/mocktail.dart';

import '_support/background_fakes.dart';

void main() {
  setUpAll(registerJobFallbacks);

  final gi = role(1, Game.genshin);
  final hsr = role(2, Game.starRail);
  final hi3 = role(3, Game.hi3);
  final disabled = role(4, Game.zzz, enabled: false);
  final healthy = account('800000001', [gi, hsr, hi3, disabled]);

  Future<void> enableCheckIn(
    JobsHarness h, {
    Set<Game> games = const {Game.genshin},
    int runAtMinutes = 9 * 60,
  }) async {
    final history = h.container.read(checkInHistoryRepositoryProvider);
    for (final game in Game.values) {
      await history.setGameEnabled(game, enabled: games.contains(game));
    }
    await history.setRunAtMinutes(runAtMinutes);
  }

  Future<JobsHarness> harness(
    List<List<AccountSummary>> snapshots, {
    FakeNotesRepository? notes,
    DateTime? now,
  }) async {
    final h = JobsHarness(accountSnapshots: snapshots, notes: notes, now: now);
    addTearDown(h.dispose);
    await enableCheckIn(h, games: const {});
    return h;
  }

  Future<void> saveSettings(JobsHarness h, NotificationSettings settings) =>
      h.container.read(notificationSettingsRepositoryProvider).save(settings);

  void stubRun(JobsHarness h, List<CheckInRecord> records) => when(
    () => h.run(
      roles: any(named: 'roles'),
      games: any(named: 'games'),
    ),
  ).thenAnswer((_) async => CheckInRun(runAt: h.now, records: records));

  CheckInRecord record(Game game, CheckInResult result) => CheckInRecord(
    accountId: '800000001',
    game: game,
    day: '2026-11-05',
    result: result,
    runAt: jobsNow,
  );

  RedeemCode code(Game game, String value) => RedeemCode(
    game: game,
    code: value,
    rewards: const [60],
    active: true,
    firstSeenAt: jobsNow,
    unread: true,
  );

  WebEvent event(String id, Game game, {bool remind = false}) => WebEvent(
    id: id,
    game: game,
    name: 'Event $id',
    summary: 'Summary',
    startAt: jobsNow,
    endAt: jobsNow.add(const Duration(hours: 12)),
    webPath: '/event/$id',
    active: true,
    remind: remind,
    unread: true,
    firstSeenAt: jobsNow,
  );

  group('refreshNotes', () {
    test(
      'refreshes every enabled dashboard role and replans notifications',
      () async {
        final h = await harness([
          [healthy],
        ]);

        await BackgroundJobs(h.container).refreshNotes();

        expect(h.notes.refreshed, [gi, hsr]);
        final roles =
            verify(
                  () => h.reschedule(
                    roles: captureAny(named: 'roles'),
                    settings: any(named: 'settings'),
                    localeCode: any(named: 'localeCode'),
                  ),
                ).captured.single
                as List<SavedRole>;
        expect(roles, [gi, hsr]);
        verify(
          () => h.widgets(
            roles: [gi, hsr],
            checkInGames: const <Game>{},
            labels: any(named: 'labels'),
          ),
        ).called(1);
        expect(h.service.shown, isEmpty);
      },
    );

    test('skips accounts that are expired or need login', () async {
      final expired = account('800000002', [
        role(5, Game.genshin, accountId: '800000002'),
      ], status: AccountStatus.expired);
      final needsLogin = account('800000003', [
        role(6, Game.zzz, accountId: '800000003'),
      ], status: AccountStatus.needsLogin);
      final h = await harness([
        [expired, needsLogin],
      ]);

      await BackgroundJobs(h.container).refreshNotes();

      expect(h.notes.refreshed, isEmpty);
    });

    test('logs a failed role and keeps refreshing the others', () async {
      final h = await harness([
        [healthy],
      ], notes: FakeNotesRepository(failing: {1}));

      await BackgroundJobs(h.container).refreshNotes();

      expect(h.notes.refreshed, [gi, hsr]);
      expect(
        h.warnings,
        contains(contains('background refresh genshin: NetworkException')),
      );
    });

    test(
      'posts one cookie-expired notification when an account turns expired',
      () async {
        final expiredAfter = healthy.copyWith(status: AccountStatus.expired);
        final h = await harness([
          [healthy],
          [expiredAfter],
        ]);

        await BackgroundJobs(h.container).refreshNotes();

        final cookie = h.service.shown
            .where((n) => n.kind == NotificationKind.cookieExpired)
            .toList();
        expect(cookie, hasLength(1));
        expect(cookie.single.body, contains('Player 800000001'));
      },
    );

    test('does not notify an account that was already expired', () async {
      final expired = healthy.copyWith(status: AccountStatus.expired);
      final h = await harness([
        [expired],
      ]);

      await BackgroundJobs(h.container).refreshNotes();

      expect(h.service.shown, isEmpty);
    });

    test('does not notify expiry while notifications are off', () async {
      final h = await harness([
        [healthy],
        [healthy.copyWith(status: AccountStatus.expired)],
      ]);
      await saveSettings(h, const NotificationSettings(enabled: false));

      await BackgroundJobs(h.container).refreshNotes();

      expect(h.service.shown, isEmpty);
    });

    test('runs the auto check-in once it is due and not yet run', () async {
      final h = await harness([
        [healthy],
      ]);
      await enableCheckIn(h);
      stubRun(h, [record(Game.genshin, CheckInResult.claimed)]);

      await BackgroundJobs(h.container).refreshNotes();

      verify(() => h.run(roles: [gi, hsr, hi3], games: {Game.genshin}))
          .called(1);
      verify(
        () => h.widgets(
          roles: any(named: 'roles'),
          checkInGames: {Game.genshin},
          labels: any(named: 'labels'),
        ),
      ).called(1);
    });

    test('waits with the check-in until the run time', () async {
      final h = await harness([
        [healthy],
      ]);
      await enableCheckIn(h, runAtMinutes: 11 * 60);

      await BackgroundJobs(h.container).refreshNotes();

      verifyNever(
        () => h.run(
          roles: any(named: 'roles'),
          games: any(named: 'games'),
        ),
      );
    });

    test('skips the check-in when it already ran today', () async {
      final h = await harness([
        [healthy],
      ]);
      await enableCheckIn(h);
      await h.db
          .into(h.db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: '800000001',
              nickname: 'Player',
              status: AccountStatus.valid,
              createdAt: jobsNow,
              updatedAt: jobsNow,
            ),
          );
      await h.container.read(checkInHistoryRepositoryProvider).addAll([
        record(Game.genshin, CheckInResult.claimed),
      ]);

      await BackgroundJobs(h.container).refreshNotes();

      verifyNever(
        () => h.run(
          roles: any(named: 'roles'),
          games: any(named: 'games'),
        ),
      );
    });
  });

  group('codes and events piggyback', () {
    test('notifies new codes only for games the user plays', () async {
      final h = await harness([
        [healthy],
      ]);
      when(h.codes.refresh).thenAnswer(
        (_) async => [code(Game.genshin, 'GIFTCODE1'), code(Game.zzz, 'ZZZ1')],
      );

      await BackgroundJobs(h.container).refreshNotes();

      final shown = h.service.shown.single;
      expect(shown.kind, NotificationKind.newCodes);
      expect(shown.body, startsWith('GIFTCODE1'));
      expect(shown.payload, contains('code=GIFTCODE1'));
    });

    test('stays quiet about codes when the codes alert is off', () async {
      final h = await harness([
        [healthy],
      ]);
      await saveSettings(h, const NotificationSettings(codes: false));
      when(h.codes.refresh)
          .thenAnswer((_) async => [code(Game.genshin, 'GIFTCODE1')]);

      await BackgroundJobs(h.container).refreshNotes();

      expect(h.service.shown, isEmpty);
    });

    test('logs a failed codes check and continues', () async {
      final h = await harness([
        [healthy],
      ]);
      when(h.codes.refresh).thenThrow(const NetworkException());

      await BackgroundJobs(h.container).refreshNotes();

      expect(h.warnings, contains(contains('codes check: NetworkException')));
      verify(h.events.refresh).called(1);
    });

    test('groups new events per game and notifies ending events', () async {
      final h = await harness([
        [healthy],
      ]);
      when(h.events.refresh).thenAnswer(
        (_) async => [
          event('1', Game.genshin),
          event('2', Game.genshin),
          event('3', Game.zzz),
        ],
      );
      when(() => h.events.takeEndingSoon(const Duration(days: 1)))
          .thenAnswer((_) async => [event('4', Game.starRail, remind: true)]);

      await BackgroundJobs(h.container).refreshNotes();

      final fresh = h.service.shown
          .where((n) => n.kind == NotificationKind.newEvents)
          .toList();
      expect(fresh, hasLength(1));
      expect(fresh.single.title, contains('2 new events'));
      expect(fresh.single.body, 'Event 1 · Event 2');
      final ending = h.service.shown
          .where((n) => n.kind == NotificationKind.eventEnding)
          .single;
      expect(ending.body, 'Event 4');
      expect(ending.payload, endsWith('/event/4'));
    });

    test('stays quiet about events when the events alert is off', () async {
      final h = await harness([
        [healthy],
      ]);
      await saveSettings(h, const NotificationSettings(events: false));
      when(h.events.refresh)
          .thenAnswer((_) async => [event('1', Game.genshin)]);

      await BackgroundJobs(h.container).refreshNotes();

      expect(h.service.shown, isEmpty);
    });

    test('logs a failed events check and continues', () async {
      final h = await harness([
        [healthy],
      ]);
      when(h.events.refresh).thenThrow(const NetworkException());

      await BackgroundJobs(h.container).refreshNotes();

      expect(h.warnings, contains(contains('events check: NetworkException')));
      verifyNever(() => h.events.takeEndingSoon(any()));
    });
  });

  group('gacha piggyback', () {
    test('syncs only games with a valid link and logs failures', () async {
      final h = await harness([
        [healthy],
      ]);
      when(() => h.gacha.linkExpiresAt(Game.genshin))
          .thenAnswer((_) async => jobsNow.add(const Duration(hours: 5)));
      when(() => h.gacha.linkExpiresAt(Game.zzz))
          .thenAnswer((_) async => jobsNow.add(const Duration(hours: 5)));
      when(() => h.gacha.sync(Game.genshin)).thenAnswer((_) async => 3);
      when(() => h.gacha.sync(Game.zzz))
          .thenThrow(const AuthkeyExpiredException());

      await BackgroundJobs(h.container).refreshNotes();

      verify(() => h.gacha.sync(Game.genshin)).called(1);
      verifyNever(() => h.gacha.sync(Game.starRail));
      expect(
        h.warnings,
        contains(contains('gacha sync zzz: AuthkeyExpiredException')),
      );
    });
  });

  group('autoCheckIn', () {
    test('runs before the run time and posts failed games', () async {
      final h = await harness([
        [healthy],
      ], now: DateTime(2026, 11, 5, 6));
      await enableCheckIn(h, games: {Game.genshin, Game.hi3});
      stubRun(h, [
        record(Game.genshin, CheckInResult.claimed),
        record(Game.hi3, CheckInResult.captcha),
      ]);

      await BackgroundJobs(h.container).autoCheckIn();

      final shown = h.service.shown.single;
      expect(shown.id, BackgroundJobs.checkInResultId);
      expect(shown.kind, NotificationKind.checkInResult);
      expect(shown.title, 'Check-in failed for 1 game');
      expect(shown.body, 'HI3');
    });

    test('posts nothing when every game succeeds', () async {
      final h = await harness([
        [healthy],
      ]);
      await enableCheckIn(h);
      stubRun(h, [record(Game.genshin, CheckInResult.alreadyClaimed)]);

      await BackgroundJobs(h.container).autoCheckIn();

      expect(h.service.shown, isEmpty);
    });

    test('posts nothing when the check-in result alert is off', () async {
      final h = await harness([
        [healthy],
      ]);
      await enableCheckIn(h);
      await saveSettings(h, const NotificationSettings(checkInResult: false));
      stubRun(h, [record(Game.genshin, CheckInResult.failed)]);

      await BackgroundJobs(h.container).autoCheckIn();

      expect(h.service.shown, isEmpty);
    });

    test('leaves out roles of accounts that need attention', () async {
      final expiredRole = role(7, Game.genshin, accountId: '800000002');
      final h = await harness([
        [
          healthy,
          account('800000002', [expiredRole], status: AccountStatus.expired),
        ],
      ]);
      await enableCheckIn(h);
      stubRun(h, const []);

      await BackgroundJobs(h.container).autoCheckIn();

      verify(() => h.run(roles: [gi, hsr, hi3], games: {Game.genshin}))
          .called(1);
    });

    test('does nothing without auto check-in games', () async {
      final h = await harness([
        [healthy],
      ]);

      await BackgroundJobs(h.container).autoCheckIn();

      verifyNever(
        () => h.run(
          roles: any(named: 'roles'),
          games: any(named: 'games'),
        ),
      );
    });
  });

  group('nextAutoCheckInDelay', () {
    test('is null when no game has auto check-in', () async {
      final h = await harness([
        [healthy],
      ]);

      expect(await BackgroundJobs(h.container).nextAutoCheckInDelay(), isNull);
    });

    test('points to the next day at the configured minute', () async {
      final h = await harness([
        [healthy],
      ]);
      await enableCheckIn(h, runAtMinutes: 9 * 60 + 30);

      final delay = await BackgroundJobs(h.container).nextAutoCheckInDelay();

      expect(delay, const Duration(hours: 23, minutes: 30));
    });

    test('points to later today before the run time', () async {
      final h = await harness([
        [healthy],
      ]);
      await enableCheckIn(h, runAtMinutes: 12 * 60);

      final delay = await BackgroundJobs(h.container).nextAutoCheckInDelay();

      expect(delay, const Duration(hours: 2));
    });
  });
}
