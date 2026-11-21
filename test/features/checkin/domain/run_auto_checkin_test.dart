import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_month.dart';
import 'package:hoyo_aio/features/checkin/domain/run_auto_checkin.dart';

import '../_support/fake_check_in_repositories.dart';

final _now = DateTime(2026, 11, 5, 9, 1);

SavedRole _role(int id, Game game, {String accountId = '800000001'}) =>
    SavedRole(
      id: id,
      accountId: accountId,
      game: game,
      uid: '80000000$id',
      server: 'os_asia',
      nickname: 'Tester $id',
      level: 60,
      enabled: true,
    );

void main() {
  test('dayKey pads year, month and day', () {
    expect(RunAutoCheckIn.dayKey(DateTime(2026, 3, 7)), '2026-03-07');
  });

  test('records mixed results and stores them in history', () async {
    final checkIn = FakeCheckInRepository(
      month: (_, game) => sampleMonth(game, signedToday: game == Game.zzz),
      claim: (_, game) => switch (game) {
        Game.genshin => ClaimOutcome.claimed,
        Game.starRail => ClaimOutcome.captcha,
        _ => ClaimOutcome.alreadyClaimed,
      },
    );
    final history = FakeCheckInHistoryRepository();
    final run = RunAutoCheckIn(checkIn, history, () => _now);

    final result = await run(
      roles: [
        _role(1, Game.genshin),
        _role(2, Game.starRail),
        _role(3, Game.zzz),
        _role(4, Game.hi3),
      ],
      games: Game.values.toSet(),
    );

    expect(result.runAt, _now);
    expect(
      {for (final r in result.records) r.game: r.result},
      {
        Game.genshin: CheckInResult.claimed,
        Game.starRail: CheckInResult.captcha,
        Game.zzz: CheckInResult.alreadyClaimed,
        Game.hi3: CheckInResult.alreadyClaimed,
      },
    );
    expect(result.records.first.reward, 'Mora ×5000');
    expect(
      result.records.firstWhere((r) => r.game == Game.starRail).reward,
      isNull,
    );
    expect(result.records.every((r) => r.day == '2026-11-05'), isTrue);
    expect(history.added.single, result.records);
    expect(checkIn.calls, isNot(contains('claim:800000001:zzz')));
  });

  test('maps expired cookie, missing role and other errors', () async {
    final checkIn = FakeCheckInRepository(
      month: (_, game) => switch (game) {
        Game.genshin => throw const CookieExpiredException(),
        Game.starRail => throw const NoRolesException(),
        Game.zzz => throw const NetworkException(),
        Game.hi3 => sampleMonth(game),
      },
      claim: (_, _) => throw const ServerException(retcode: -1),
    );
    final history = FakeCheckInHistoryRepository();
    final run = RunAutoCheckIn(checkIn, history, () => _now);

    final result = await run(
      roles: [for (final game in Game.values) _role(game.index, game)],
      games: Game.values.toSet(),
    );

    expect(
      {for (final r in result.records) r.game: r.result},
      {
        Game.genshin: CheckInResult.cookieExpired,
        Game.starRail: CheckInResult.noRole,
        Game.zzz: CheckInResult.failed,
        Game.hi3: CheckInResult.failed,
      },
    );
    expect(result.successCount, 0);
    expect(history.added.single, hasLength(4));
  });

  test('runs only enabled games and each account and game once', () async {
    final checkIn = FakeCheckInRepository();
    final history = FakeCheckInHistoryRepository();
    final run = RunAutoCheckIn(checkIn, history, () => _now);

    final result = await run(
      roles: [
        _role(1, Game.genshin),
        _role(2, Game.genshin),
        _role(3, Game.genshin, accountId: '800000002'),
        _role(4, Game.starRail),
      ],
      games: {Game.genshin},
    );

    expect(result.records.map((r) => (r.accountId, r.game)), [
      ('800000001', Game.genshin),
      ('800000002', Game.genshin),
    ]);
    expect(checkIn.calls.where((c) => c.contains('starRail')), isEmpty);
  });

  test('runs roles one after another', () async {
    var active = 0;
    var maxActive = 0;
    Future<ClaimOutcome> slowClaim(String _, Game _) async {
      active++;
      maxActive = active > maxActive ? active : maxActive;
      await Future<void>.delayed(Duration.zero);
      active--;
      return ClaimOutcome.claimed;
    }

    final checkIn = FakeCheckInRepository(claim: slowClaim);
    final run = RunAutoCheckIn(
      checkIn,
      FakeCheckInHistoryRepository(),
      () => _now,
    );

    await run(
      roles: [_role(1, Game.genshin), _role(2, Game.starRail)],
      games: Game.values.toSet(),
    );

    expect(maxActive, 1);
    expect(checkIn.calls, [
      'month:800000001:genshin',
      'claim:800000001:genshin',
      'month:800000001:starRail',
      'claim:800000001:starRail',
    ]);
  });

  test('stores an empty run when nothing is enabled', () async {
    final history = FakeCheckInHistoryRepository();
    final run = RunAutoCheckIn(FakeCheckInRepository(), history, () => _now);

    final result = await run(roles: [_role(1, Game.genshin)], games: {});

    expect(result.records, isEmpty);
    expect(history.added.single, isEmpty);
  });
}
