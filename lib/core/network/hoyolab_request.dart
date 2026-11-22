import 'package:dio/dio.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';

enum HeaderProfile { gameRecord, zzzNotes, checkIn, community, warpRecords }

abstract final class HoyolabExtras {
  static const accountId = 'hoyo.accountId';
  static const profile = 'hoyo.profile';
  static const game = 'hoyo.game';
  static const retryCount = 'hoyo.retryCount';
  static const extraCookie = 'hoyo.extraCookie';
  static const keepAccountOnExpired = 'hoyo.keepAccountOnExpired';
}

Options hoyolabOptions({
  required String accountId,
  required HeaderProfile profile,
  Game? game,
  String? extraCookie,
  bool keepAccountOnExpired = false,
}) => Options(
  extra: {
    HoyolabExtras.accountId: accountId,
    HoyolabExtras.profile: profile,
    HoyolabExtras.game: ?game,
    HoyolabExtras.extraCookie: ?extraCookie,
    if (keepAccountOnExpired) HoyolabExtras.keepAccountOnExpired: true,
  },
);

Options communityOptions() =>
    Options(extra: {HoyolabExtras.profile: HeaderProfile.community});

extension HoyolabRequestOptions on RequestOptions {
  String? get hoyolabAccountId => extra[HoyolabExtras.accountId] as String?;

  HeaderProfile? get hoyolabProfile =>
      extra[HoyolabExtras.profile] as HeaderProfile?;

  Game? get hoyolabGame => extra[HoyolabExtras.game] as Game?;

  String? get hoyolabExtraCookie => extra[HoyolabExtras.extraCookie] as String?;

  bool get hoyolabKeepAccountOnExpired =>
      extra[HoyolabExtras.keepAccountOnExpired] == true;

  int get hoyolabRetryCount => extra[HoyolabExtras.retryCount] as int? ?? 0;
}
