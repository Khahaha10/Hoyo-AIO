import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoyo_aio/core/network/lenient_int.dart';

part 'star_rail_note_dto.freezed.dart';
part 'star_rail_note_dto.g.dart';

@freezed
abstract class StarRailNoteDto with _$StarRailNoteDto {
  @JsonSerializable(converters: [LenientInt()])
  const factory StarRailNoteDto({
    @Default(0) int currentStamina,
    @Default(0) int maxStamina,
    @Default(0) int staminaRecoverTime,
    @Default(0) int staminaFullTs,
    @Default(0) int currentTs,
    @Default(0) int currentReserveStamina,
    @Default(false) bool isReserveStaminaFull,
    @Default(0) int totalExpeditionNum,
    @Default(<StarRailExpeditionDto>[]) List<StarRailExpeditionDto> expeditions,
    @Default(0) int currentTrainScore,
    @Default(0) int maxTrainScore,
    @Default(0) int currentRogueScore,
    @Default(0) int maxRogueScore,
    @Default(0) int weeklyCocoonCnt,
    @Default(0) int weeklyCocoonLimit,
  }) = _StarRailNoteDto;

  factory StarRailNoteDto.fromJson(Map<String, dynamic> json) =>
      _$StarRailNoteDtoFromJson(json);
}

@freezed
abstract class StarRailExpeditionDto with _$StarRailExpeditionDto {
  @JsonSerializable(converters: [LenientInt()])
  const factory StarRailExpeditionDto({
    String? name,
    @Default('') String status,
    @Default(0) int remainingTime,
  }) = _StarRailExpeditionDto;

  factory StarRailExpeditionDto.fromJson(Map<String, dynamic> json) =>
      _$StarRailExpeditionDtoFromJson(json);
}
