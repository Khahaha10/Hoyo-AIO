import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_record.dart';

abstract interface class CheckInHistoryRepository {
  Future<void> addAll(List<CheckInRecord> records);

  Stream<List<CheckInRun>> watchRuns({required int limit});

  Stream<AutoCheckInSettings> watchSettings();

  Future<void> setGameEnabled(Game game, {required bool enabled});

  Future<void> setRunAtMinutes(int minutes);
}
