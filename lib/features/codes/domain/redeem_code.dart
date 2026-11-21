import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';

part 'redeem_code.freezed.dart';

@freezed
abstract class RedeemCode with _$RedeemCode {
  const factory RedeemCode({
    required Game game,
    required String code,
    required List<int> rewards,
    required bool active,
    required DateTime firstSeenAt,
    required bool unread,
    DateTime? expiresAt,
    DateTime? redeemedAt,
  }) = _RedeemCode;

  const RedeemCode._();

  bool isExpiredAt(DateTime now) =>
      !active || (expiresAt?.isBefore(now) ?? false);
}
