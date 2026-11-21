import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_month.dart';

abstract interface class CheckInRepository {
  Future<CheckInMonth> month({required String accountId, required Game game});

  Future<ClaimOutcome> claim({required String accountId, required Game game});
}
