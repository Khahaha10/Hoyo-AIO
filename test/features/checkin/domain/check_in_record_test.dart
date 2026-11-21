import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_record.dart';

CheckInRecord _record(CheckInResult result, [Game game = Game.genshin]) =>
    CheckInRecord(
      accountId: '800000001',
      game: game,
      day: '2026-11-05',
      result: result,
      runAt: DateTime(2026, 11, 5, 6),
    );

void main() {
  test('claimed and alreadyClaimed count as success', () {
    for (final result in CheckInResult.values) {
      expect(
        _record(result).isSuccess,
        result == CheckInResult.claimed ||
            result == CheckInResult.alreadyClaimed,
        reason: result.name,
      );
    }
  });

  test('CheckInRun counts successes and finds the first failure', () {
    final run = CheckInRun(
      runAt: DateTime(2026, 11, 5, 6),
      records: [
        _record(CheckInResult.claimed),
        _record(CheckInResult.captcha, Game.starRail),
        _record(CheckInResult.failed, Game.zzz),
      ],
    );

    expect(run.successCount, 1);
    expect(run.firstFailure?.game, Game.starRail);
  });

  test('CheckInRun without failures has no firstFailure', () {
    final run = CheckInRun(
      runAt: DateTime(2026, 11, 5, 6),
      records: [_record(CheckInResult.alreadyClaimed)],
    );

    expect(run.firstFailure, isNull);
  });

  group('AutoCheckInSettings.nextRunAfter', () {
    const settings = AutoCheckInSettings(games: {}, runAtMinutes: 9 * 60);

    test('returns today when the run time is still ahead', () {
      expect(
        settings.nextRunAfter(DateTime(2026, 11, 5, 8, 59)),
        DateTime(2026, 11, 5, 9),
      );
    });

    test('returns tomorrow at or after the run time', () {
      expect(
        settings.nextRunAfter(DateTime(2026, 11, 5, 9)),
        DateTime(2026, 11, 6, 9),
      );
      expect(
        settings.nextRunAfter(DateTime(2026, 11, 30, 23)),
        DateTime(2026, 12, 1, 9),
      );
    });
  });
}
