import 'package:dio/dio.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';

enum HeaderProfile { gameRecord, zzzNotes, checkIn }

abstract final class HoyolabExtras {
  static const accountId = 'hoyo.accountId';
  static const profile = 'hoyo.profile';
  static const game = 'hoyo.game';
  static const retryCount = 'hoyo.retryCount';
}

Options hoyolabOptions({
  required String accountId,
  required HeaderProfile profile,
  Game? game,
}) => Options(
  extra: {
    HoyolabExtras.accountId: accountId,
    HoyolabExtras.profile: profile,
    HoyolabExtras.game: ?game,
  },
);

extension HoyolabRequestOptions on RequestOptions {
  String? get hoyolabAccountId => extra[HoyolabExtras.accountId] as String?;

  HeaderProfile? get hoyolabProfile =>
      extra[HoyolabExtras.profile] as HeaderProfile?;

  Game? get hoyolabGame => extra[HoyolabExtras.game] as Game?;

  int get hoyolabRetryCount => extra[HoyolabExtras.retryCount] as int? ?? 0;
}
