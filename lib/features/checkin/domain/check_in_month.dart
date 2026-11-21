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
abstract class CheckInMonth with _$CheckInMonth {
  const factory CheckInMonth({
    required Game game,
    required int month,
    required int signedDays,
    required bool signedToday,
    required int missedDays,
    required String today,
    required List<CheckInReward> rewards,
  }) = _CheckInMonth;

  const CheckInMonth._();

  int get todayIndex => signedToday ? signedDays : signedDays + 1;

  CheckInReward? get todayReward =>
      rewards.where((reward) => reward.day == todayIndex).firstOrNull;

  DateTime? get date => DateTime.tryParse(today);

  int get claimsLeft {
    final current = date;
    if (current == null) return rewards.length - signedDays;
    final daysInMonth = DateTime(current.year, current.month + 1, 0).day;
    return daysInMonth - current.day + (signedToday ? 0 : 1);
  }

  int get reachableDays => signedDays + claimsLeft;

  int get unreachableDays =>
      (rewards.length - reachableDays).clamp(0, rewards.length);

  CheckInDayStatus statusOf(int day) {
    if (day <= signedDays) return CheckInDayStatus.claimed;
    if (!signedToday && day == todayIndex) return CheckInDayStatus.today;
    if (day > reachableDays) return CheckInDayStatus.missed;
    return CheckInDayStatus.upcoming;
  }
}
