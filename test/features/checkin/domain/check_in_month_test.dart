import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_month.dart';

List<CheckInReward> _rewards(int count) => [
  for (var day = 1; day <= count; day++)
    CheckInReward(day: day, name: 'Reward $day', count: day),
];

CheckInMonth _month({
  int signedDays = 3,
  bool signedToday = false,
  String today = '2026-11-05',
  Map<int, CheckInReward>? claimedOn,
  int rewards = 30,
}) => CheckInMonth(
  game: Game.genshin,
  month: 11,
  signedDays: signedDays,
  signedToday: signedToday,
  missedDays: 0,
  today: today,
  rewards: _rewards(rewards),
  claimedOn: claimedOn,
);

List<CheckInDayStatus> _statuses(CheckInMonth month) =>
    month.days.map((d) => d.status).toList();

void main() {
  group('todayIndex and todayReward', () {
    test('points to the next reward when today is not claimed', () {
      final month = _month(signedDays: 3);

      expect(month.todayIndex, 4);
      expect(month.todayReward?.day, 4);
    });

    test('points to the claimed reward when today is claimed', () {
      final month = _month(signedDays: 3, signedToday: true);

      expect(month.todayIndex, 3);
      expect(month.todayReward?.day, 3);
    });

    test('is null past the last reward', () {
      final month = _month(signedDays: 30, rewards: 30);

      expect(month.todayReward, isNull);
    });
  });

  group('dates', () {
    test('uses the calendar day and month length from today', () {
      final month = _month(today: '2026-02-10');

      expect(month.date, DateTime(2026, 2, 10));
      expect(month.todayDate, 10);
      expect(month.daysInMonth, 28);
      expect(month.days, hasLength(28));
    });

    test('falls back to the reward index and count without a date', () {
      final month = _month(today: '', signedDays: 2, rewards: 20);

      expect(month.date, isNull);
      expect(month.todayDate, 3);
      expect(month.daysInMonth, 20);
    });
  });

  group('days from award history', () {
    test('marks claimed and missed days by real dates', () {
      final month = _month(
        today: '2026-11-05',
        signedDays: 2,
        claimedOn: {
          1: const CheckInReward(day: 1, name: 'A', count: 1),
          3: const CheckInReward(day: 3, name: 'B', count: 2),
        },
      );

      expect(_statuses(month).take(6), [
        CheckInDayStatus.claimed,
        CheckInDayStatus.missed,
        CheckInDayStatus.claimed,
        CheckInDayStatus.missed,
        CheckInDayStatus.today,
        CheckInDayStatus.upcoming,
      ]);
      expect(month.days[2].reward?.name, 'B');
      expect(month.days[1].reward, isNull);
      expect(month.missedCount, 2);
    });

    test('shows today as claimed with the history reward', () {
      final month = _month(
        today: '2026-11-03',
        signedDays: 1,
        signedToday: true,
        claimedOn: {3: const CheckInReward(day: 3, name: 'Got', count: 5)},
      );

      final today = month.days[2];
      expect(today.status, CheckInDayStatus.claimed);
      expect(today.reward?.name, 'Got');
      expect(month.missedCount, 2);
    });

    test('ignores history entries on or after today for past days', () {
      final month = _month(
        today: '2026-11-02',
        signedDays: 1,
        claimedOn: {5: const CheckInReward(day: 5, name: 'X', count: 1)},
      );

      expect(month.missedCount, 1);
    });

    test('numbers upcoming rewards after the next claim', () {
      final month = _month(today: '2026-11-05', signedDays: 3, claimedOn: {});

      expect(month.days[4].reward?.day, 4);
      expect(month.days[5].reward?.day, 5);
      expect(month.days[29].reward?.day, 29);
    });
  });

  group('days without award history', () {
    test('treats the first claimed days as claimed', () {
      final month = _month(today: '2026-11-05', signedDays: 3);

      expect(_statuses(month).take(5), [
        CheckInDayStatus.claimed,
        CheckInDayStatus.claimed,
        CheckInDayStatus.claimed,
        CheckInDayStatus.missed,
        CheckInDayStatus.today,
      ]);
      expect(month.missedCount, 1);
      expect(month.days.first.reward?.day, 1);
    });

    test('does not count today as a past claim', () {
      final month = _month(
        today: '2026-11-04',
        signedDays: 4,
        signedToday: true,
      );

      expect(month.missedCount, 0);
      expect(month.days[3].status, CheckInDayStatus.claimed);
    });

    test('has no past days on the first of the month', () {
      final month = _month(today: '2026-11-01', signedDays: 0);

      expect(month.days.first.status, CheckInDayStatus.today);
      expect(month.missedCount, 0);
    });
  });
}
