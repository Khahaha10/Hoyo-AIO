import 'package:freezed_annotation/freezed_annotation.dart';

part 'record_card_dto.freezed.dart';
part 'record_card_dto.g.dart';

@freezed
abstract class RecordCardDto with _$RecordCardDto {
  const factory RecordCardDto({
    @Default(-1) int gameId,
    @Default('') String gameRoleId,
    @Default('') String nickname,
    @Default('') String region,
    String? regionName,
    @Default(0) int level,
    @Default(true) bool hasRole,
  }) = _RecordCardDto;

  factory RecordCardDto.fromJson(Map<String, dynamic> json) =>
      _$RecordCardDtoFromJson(json);
}
