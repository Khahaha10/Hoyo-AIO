import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoyo_aio/core/network/lenient_int.dart';

part 'genshin_note_dto.freezed.dart';
part 'genshin_note_dto.g.dart';

@freezed
abstract class GenshinNoteDto with _$GenshinNoteDto {
  @JsonSerializable(converters: [LenientInt()])
  const factory GenshinNoteDto({
    @Default(0) int currentResin,
    @Default(0) int maxResin,
    @Default(0) int resinRecoveryTime,
    @Default(0) int finishedTaskNum,
    @Default(0) int totalTaskNum,
    @Default(false) bool isExtraTaskRewardReceived,
    @Default(0) int remainResinDiscountNum,
    @Default(0) int resinDiscountNumLimit,
    @Default(0) int currentHomeCoin,
    @Default(0) int maxHomeCoin,
    @Default(0) int homeCoinRecoveryTime,
    @Default(0) int maxExpeditionNum,
    @Default(<GenshinExpeditionDto>[]) List<GenshinExpeditionDto> expeditions,
    GenshinTransformerDto? transformer,
  }) = _GenshinNoteDto;

  factory GenshinNoteDto.fromJson(Map<String, dynamic> json) =>
      _$GenshinNoteDtoFromJson(json);
}

@freezed
abstract class GenshinExpeditionDto with _$GenshinExpeditionDto {
  @JsonSerializable(converters: [LenientInt()])
  const factory GenshinExpeditionDto({
    @Default('') String status,
    @Default(0) int remainedTime,
  }) = _GenshinExpeditionDto;

  factory GenshinExpeditionDto.fromJson(Map<String, dynamic> json) =>
      _$GenshinExpeditionDtoFromJson(json);
}

@freezed
abstract class GenshinTransformerDto with _$GenshinTransformerDto {
  const factory GenshinTransformerDto({
    @Default(false) bool obtained,
    GenshinTransformerTimeDto? recoveryTime,
  }) = _GenshinTransformerDto;

  factory GenshinTransformerDto.fromJson(Map<String, dynamic> json) =>
      _$GenshinTransformerDtoFromJson(json);
}

@freezed
abstract class GenshinTransformerTimeDto with _$GenshinTransformerTimeDto {
  @JsonSerializable(converters: [LenientInt()])
  const factory GenshinTransformerTimeDto({
    @JsonKey(name: 'Day') @Default(0) int day,
    @JsonKey(name: 'Hour') @Default(0) int hour,
    @JsonKey(name: 'Minute') @Default(0) int minute,
    @JsonKey(name: 'Second') @Default(0) int second,
    @Default(false) bool reached,
  }) = _GenshinTransformerTimeDto;

  factory GenshinTransformerTimeDto.fromJson(Map<String, dynamic> json) =>
      _$GenshinTransformerTimeDtoFromJson(json);
}
