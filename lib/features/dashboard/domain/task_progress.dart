import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_progress.freezed.dart';

@freezed
abstract class TaskProgress with _$TaskProgress {
  const factory TaskProgress({required int done, required int total}) =
      _TaskProgress;

  const TaskProgress._();

  bool get isComplete => total > 0 && done >= total;
}
