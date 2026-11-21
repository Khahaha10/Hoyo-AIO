import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';

part 'check_in_month.freezed.dart';

enum ClaimOutcome { claimed, alreadyClaimed, captcha }

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
}
