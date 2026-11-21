import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoyo_aio/core/network/lenient_int.dart';

part 'zzz_note_dto.freezed.dart';
part 'zzz_note_dto.g.dart';

@freezed
abstract class ZzzNoteDto with _$ZzzNoteDto {
  const factory ZzzNoteDto({
    @Default(ZzzEnergyDto()) ZzzEnergyDto energy,
    @Default(ZzzProgressDto()) ZzzProgressDto vitality,
    ZzzVhsSaleDto? vhsSale,
    String? cardSign,
    ZzzCountDto? bountyCommission,
    ZzzWeeklyTaskDto? weeklyTask,
  }) = _ZzzNoteDto;

  factory ZzzNoteDto.fromJson(Map<String, dynamic> json) =>
      _$ZzzNoteDtoFromJson(json);
}

@freezed
abstract class ZzzEnergyDto with _$ZzzEnergyDto {
  @JsonSerializable(converters: [LenientInt()])
  const factory ZzzEnergyDto({
    @Default(ZzzProgressDto()) ZzzProgressDto progress,
    @Default(0) int restore,
  }) = _ZzzEnergyDto;

  factory ZzzEnergyDto.fromJson(Map<String, dynamic> json) =>
      _$ZzzEnergyDtoFromJson(json);
}

@freezed
abstract class ZzzProgressDto with _$ZzzProgressDto {
  @JsonSerializable(converters: [LenientInt()])
  const factory ZzzProgressDto({@Default(0) int current, @Default(0) int max}) =
      _ZzzProgressDto;

  factory ZzzProgressDto.fromJson(Map<String, dynamic> json) =>
      _$ZzzProgressDtoFromJson(json);
}

@freezed
abstract class ZzzVhsSaleDto with _$ZzzVhsSaleDto {
  const factory ZzzVhsSaleDto({String? saleState}) = _ZzzVhsSaleDto;

  factory ZzzVhsSaleDto.fromJson(Map<String, dynamic> json) =>
      _$ZzzVhsSaleDtoFromJson(json);
}

@freezed
abstract class ZzzCountDto with _$ZzzCountDto {
  @JsonSerializable(converters: [LenientInt()])
  const factory ZzzCountDto({@Default(0) int num, @Default(0) int total}) =
      _ZzzCountDto;

  factory ZzzCountDto.fromJson(Map<String, dynamic> json) =>
      _$ZzzCountDtoFromJson(json);
}

@freezed
abstract class ZzzWeeklyTaskDto with _$ZzzWeeklyTaskDto {
  @JsonSerializable(converters: [LenientInt()])
  const factory ZzzWeeklyTaskDto({
    @Default(0) int curPoint,
    @Default(0) int maxPoint,
  }) = _ZzzWeeklyTaskDto;

  factory ZzzWeeklyTaskDto.fromJson(Map<String, dynamic> json) =>
      _$ZzzWeeklyTaskDtoFromJson(json);
}
