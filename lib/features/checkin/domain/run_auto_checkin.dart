import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_history_repository.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_month.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_record.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_repository.dart';

class RunAutoCheckIn {
  const RunAutoCheckIn(this._checkIn, this._history, this._now);

  final CheckInRepository _checkIn;
  final CheckInHistoryRepository _history;
  final DateTime Function() _now;

  Future<CheckInRun> call({
    required List<SavedRole> roles,
    required Set<Game> games,
  }) async {
    final runAt = _now();
    final targets = {
      for (final role in roles)
        if (games.contains(role.game)) (role.accountId, role.game),
    };
    final records = <CheckInRecord>[];
    for (final (accountId, game) in targets) {
      records.add(await _runOne(accountId, game, runAt));
    }
    await _history.addAll(records);
    return CheckInRun(runAt: runAt, records: records);
  }

  Future<CheckInRecord> _runOne(
    String accountId,
    Game game,
    DateTime runAt,
  ) async {
    CheckInRecord record(CheckInResult result, [String? reward]) =>
        CheckInRecord(
          accountId: accountId,
          game: game,
          day: dayKey(runAt),
          result: result,
          runAt: runAt,
          reward: reward,
        );
    try {
      final month = await _checkIn.month(accountId: accountId, game: game);
      final reward = switch (month.todayReward) {
        final reward? => '${reward.name} ×${reward.count}',
        null => null,
      };
      if (month.signedToday) {
        return record(CheckInResult.alreadyClaimed, reward);
      }
      return switch (await _checkIn.claim(accountId: accountId, game: game)) {
        ClaimOutcome.claimed => record(CheckInResult.claimed, reward),
        ClaimOutcome.alreadyClaimed => record(
          CheckInResult.alreadyClaimed,
          reward,
        ),
        ClaimOutcome.captcha => record(CheckInResult.captcha),
      };
    } on CookieExpiredException {
      return record(CheckInResult.cookieExpired);
    } on NoRolesException {
      return record(CheckInResult.noRole);
    } on AppException {
      return record(CheckInResult.failed);
    }
  }

  static String dayKey(DateTime at) =>
      '${at.year.toString().padLeft(4, '0')}-'
      '${at.month.toString().padLeft(2, '0')}-'
      '${at.day.toString().padLeft(2, '0')}';
}
