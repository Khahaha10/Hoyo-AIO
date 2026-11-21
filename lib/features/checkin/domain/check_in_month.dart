import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';

part 'check_in_month.freezed.dart';

enum ClaimOutcome { claimed, alreadyClaimed, captcha }

enum CheckInDayStatus { claimed, today, missed, upcoming }

@freezed
abstract class CheckInReward with _$CheckInReward {
  const factory CheckInReward({
    required int day,
    required String name,
    required int count,
  }) = _CheckInReward;
}

@freezed
abstract class CheckInDay with _$CheckInDay {
  const factory CheckInDay({
    required int date,
    required CheckInDayStatus status,
    CheckInReward? reward,
  }) = _CheckInDay;
}

@freezed
abstract class CheckInMonth with _$CheckInMonth {
  const factory CheckInMonth({
    required Game game,
    required int month,
    required int signedDays,
    required bool signedToday,
    required int missedDays,
    required String today,
    required List<CheckInReward> rewards,
    Map<int, CheckInReward>? claimedOn,
  }) = _CheckInMonth;

  const CheckInMonth._();

  int get todayIndex => signedToday ? signedDays : signedDays + 1;

  CheckInReward? get todayReward =>
      rewards.where((reward) => reward.day == todayIndex).firstOrNull;

  DateTime? get date => DateTime.tryParse(today);

  int get todayDate => date?.day ?? todayIndex;

  int get daysInMonth => switch (date) {
    final current? => DateTime(current.year, current.month + 1, 0).day,
    null => rewards.length,
  };

  Map<int, CheckInReward> get _claimedBeforeToday {
    final known = claimedOn;
    if (known != null) {
      return {
        for (final MapEntry(:key, :value) in known.entries)
          if (key < todayDate) key: value,
      };
    }
    final pastClaims = signedDays - (signedToday ? 1 : 0);
    return {
      for (var day = 1; day <= pastClaims && day < todayDate; day++)
        day: ?_rewardNumber(day),
    };
  }

  int get missedCount => todayDate - 1 - _claimedBeforeToday.length;

  List<CheckInDay> get days {
    final past = _claimedBeforeToday;
    return [
      for (var day = 1; day <= daysInMonth; day++)
        if (day < todayDate)
          CheckInDay(
            date: day,
            status: past.containsKey(day)
                ? CheckInDayStatus.claimed
                : CheckInDayStatus.missed,
            reward: past[day],
          )
        else if (day == todayDate)
          CheckInDay(
            date: day,
            status: signedToday
                ? CheckInDayStatus.claimed
                : CheckInDayStatus.today,
            reward: claimedOn?[day] ?? todayReward,
          )
        else
          CheckInDay(
            date: day,
            status: CheckInDayStatus.upcoming,
            reward: _rewardNumber(todayIndex + day - todayDate),
          ),
    ];
  }

  CheckInReward? _rewardNumber(int number) =>
      rewards.where((reward) => reward.day == number).firstOrNull;
}
