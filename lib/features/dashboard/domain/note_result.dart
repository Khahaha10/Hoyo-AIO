import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';

part 'note_result.freezed.dart';

@freezed
abstract class NoteResult with _$NoteResult {
  const factory NoteResult({
    required GameNote note,
    @Default(false) bool isStale,
    AppException? error,
  }) = _NoteResult;
}
