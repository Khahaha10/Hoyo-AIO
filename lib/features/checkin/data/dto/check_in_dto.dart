import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoyo_aio/core/network/lenient_int.dart';

part 'check_in_dto.freezed.dart';
part 'check_in_dto.g.dart';

@freezed
abstract class CheckInInfoDto with _$CheckInInfoDto {
  @JsonSerializable(converters: [LenientInt()])
  const factory CheckInInfoDto({
    @Default(0) int totalSignDay,
    @Default('') String today,
    @Default(false) bool isSign,
    @Default(0) int signCntMissed,
  }) = _CheckInInfoDto;

  factory CheckInInfoDto.fromJson(Map<String, dynamic> json) =>
      _$CheckInInfoDtoFromJson(json);
}

@freezed
abstract class CheckInHomeDto with _$CheckInHomeDto {
  @JsonSerializable(converters: [LenientInt()])
  const factory CheckInHomeDto({
    @Default(0) int month,
    @Default(<CheckInAwardDto>[]) List<CheckInAwardDto> awards,
  }) = _CheckInHomeDto;

  factory CheckInHomeDto.fromJson(Map<String, dynamic> json) =>
      _$CheckInHomeDtoFromJson(json);
}

@freezed
abstract class CheckInAwardDto with _$CheckInAwardDto {
  @JsonSerializable(converters: [LenientInt()])
  const factory CheckInAwardDto({
    @Default('') String name,
    @Default(0) int cnt,
  }) = _CheckInAwardDto;

  factory CheckInAwardDto.fromJson(Map<String, dynamic> json) =>
      _$CheckInAwardDtoFromJson(json);
}

@freezed
abstract class CheckInSignDto with _$CheckInSignDto {
  const factory CheckInSignDto({
    @Default(false) bool isRisk,
    CheckInRiskDto? gtResult,
  }) = _CheckInSignDto;

  const CheckInSignDto._();

  bool get needsCaptcha => isRisk || (gtResult?.isRisk ?? false);

  factory CheckInSignDto.fromJson(Map<String, dynamic> json) =>
      _$CheckInSignDtoFromJson(json);
}

@freezed
abstract class CheckInRiskDto with _$CheckInRiskDto {
  const factory CheckInRiskDto({@Default(false) bool isRisk}) = _CheckInRiskDto;

  factory CheckInRiskDto.fromJson(Map<String, dynamic> json) =>
      _$CheckInRiskDtoFromJson(json);
}
