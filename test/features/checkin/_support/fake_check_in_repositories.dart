import 'dart:async';

import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_history_repository.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_month.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_record.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_repository.dart';

typedef MonthAnswer = FutureOr<CheckInMonth> Function(
  String accountId,
  Game game,
);
typedef ClaimAnswer = FutureOr<ClaimOutcome> Function(
  String accountId,
  Game game,
);

CheckInMonth sampleMonth(
  Game game, {
  bool signedToday = false,
  int signedDays = 3,
  String today = '2026-11-05',
  Map<int, CheckInReward>? claimedOn,
}) => CheckInMonth(
  game: game,
  month: 11,
  signedDays: signedDays,
  signedToday: signedToday,
  missedDays: 1,
  today: today,
  rewards: [
    for (var day = 1; day <= 30; day++)
      CheckInReward(
        day: day,
        name: day.isEven ? 'Mora' : 'Primogem',
        count: day.isEven ? 5000 : 20,
      ),
  ],
  claimedOn: claimedOn,
);

class FakeCheckInRepository implements CheckInRepository {
  FakeCheckInRepository({MonthAnswer? month, ClaimAnswer? claim})
    : _month = month ?? ((_, game) => sampleMonth(game)),
      _claim = claim ?? ((_, _) => ClaimOutcome.claimed);

  final MonthAnswer _month;
  final ClaimAnswer _claim;
  final calls = <String>[];

  @override
  Future<CheckInMonth> month({
    required String accountId,
    required Game game,
  }) async {
    calls.add('month:$accountId:${game.name}');
    return _month(accountId, game);
  }

  @override
  Future<ClaimOutcome> claim({
    required String accountId,
    required Game game,
  }) async {
    calls.add('claim:$accountId:${game.name}');
    return _claim(accountId, game);
  }
}

class FakeCheckInHistoryRepository implements CheckInHistoryRepository {
  FakeCheckInHistoryRepository({
    AutoCheckInSettings settings = const AutoCheckInSettings(
      games: {Game.genshin},
      runAtMinutes: 9 * 60,
    ),
    List<CheckInRun> runs = const [],
  }) : _settings = StreamController<AutoCheckInSettings>.broadcast(),
       _current = settings,
       _runs = runs;

  final StreamController<AutoCheckInSettings> _settings;
  AutoCheckInSettings _current;
  final List<CheckInRun> _runs;
  final added = <List<CheckInRecord>>[];

  AutoCheckInSettings get current => _current;

  @override
  Future<void> addAll(List<CheckInRecord> records) async => added.add(records);

  @override
  Stream<List<CheckInRun>> watchRuns({required int limit}) =>
      Stream.value(_runs.take(limit).toList());

  @override
  Future<bool> hasRunOn(String day) async =>
      added.expand((r) => r).any((r) => r.day == day);

  @override
  Future<List<CheckInRecord>> recordsOn(String day) async => [
    for (final record in added.expand((r) => r))
      if (record.day == day) record,
  ];

  @override
  Stream<AutoCheckInSettings> watchSettings() async* {
    yield _current;
    yield* _settings.stream;
  }

  @override
  Future<void> setGameEnabled(Game game, {required bool enabled}) async {
    _current = _current.copyWith(
      games: enabled
          ? {..._current.games, game}
          : _current.games.difference({game}),
    );
    _settings.add(_current);
  }

  @override
  Future<void> setRunAtMinutes(int minutes) async {
    _current = _current.copyWith(runAtMinutes: minutes);
    _settings.add(_current);
  }
}
