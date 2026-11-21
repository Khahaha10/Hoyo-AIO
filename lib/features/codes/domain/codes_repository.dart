import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/codes/domain/redeem_code.dart';

abstract interface class CodesRepository {
  Future<List<RedeemCode>> refresh();

  Stream<List<RedeemCode>> watch();

  Future<void> markAllRead();

  Future<void> markRedeemed(Game game, String code);
}
