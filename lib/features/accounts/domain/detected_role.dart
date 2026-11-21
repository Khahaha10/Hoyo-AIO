import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/game_region.dart';

part 'detected_role.freezed.dart';

@freezed
abstract class DetectedRole with _$DetectedRole {
  const factory DetectedRole({
    required Game game,
    required String uid,
    required String server,
    required GameRegion? region,
    required String nickname,
    required int level,
  }) = _DetectedRole;
}
