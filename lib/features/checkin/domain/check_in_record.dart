import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';

part 'check_in_record.freezed.dart';

@freezed
abstract class CheckInRecord with _$CheckInRecord {
  const factory CheckInRecord({
    required String accountId,
    required Game game,
    required String day,
    required CheckInResult result,
    required DateTime runAt,
    String? reward,
  }) = _CheckInRecord;

  const CheckInRecord._();

  bool get isSuccess =>
      result == CheckInResult.claimed || result == CheckInResult.alreadyClaimed;
}

@freezed
abstract class CheckInRun with _$CheckInRun {
  const factory CheckInRun({
    required DateTime runAt,
    required List<CheckInRecord> records,
  }) = _CheckInRun;

  const CheckInRun._();

  int get successCount => records.where((record) => record.isSuccess).length;

  CheckInRecord? get firstFailure =>
      records.where((record) => !record.isSuccess).firstOrNull;
}

@freezed
abstract class AutoCheckInSettings with _$AutoCheckInSettings {
  const factory AutoCheckInSettings({
    required Set<Game> games,
    required int runAtMinutes,
  }) = _AutoCheckInSettings;

  const AutoCheckInSettings._();

  DateTime nextRunAfter(DateTime now) {
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(minutes: runAtMinutes));
    return now.isBefore(today) ? today : today.add(const Duration(days: 1));
  }
}
