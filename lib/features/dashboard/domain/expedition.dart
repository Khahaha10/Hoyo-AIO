import 'package:freezed_annotation/freezed_annotation.dart';

part 'expedition.freezed.dart';

@freezed
abstract class Expedition with _$Expedition {
  const factory Expedition({required DateTime doneAt, String? name}) =
      _Expedition;

  const Expedition._();

  bool isDoneAt(DateTime now) => !now.isBefore(doneAt);

  Duration remainingAt(DateTime now) =>
      isDoneAt(now) ? Duration.zero : doneAt.difference(now);
}
