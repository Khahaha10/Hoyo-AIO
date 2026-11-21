import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';

part 'saved_role.freezed.dart';

@freezed
abstract class SavedRole with _$SavedRole {
  const factory SavedRole({
    required int id,
    required String accountId,
    required Game game,
    required String uid,
    required String server,
    required String nickname,
    required int level,
    required bool enabled,
  }) = _SavedRole;
}
