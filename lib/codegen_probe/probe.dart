import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'probe.freezed.dart';
part 'probe.g.dart';

@freezed
abstract class Probe with _$Probe {
  const factory Probe({required int value}) = _Probe;

  factory Probe.fromJson(Map<String, dynamic> json) => _$ProbeFromJson(json);
}

@riverpod
Probe probe(Ref ref) => const Probe(value: 1);
