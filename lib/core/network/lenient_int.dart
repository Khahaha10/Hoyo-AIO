import 'package:json_annotation/json_annotation.dart';

class LenientInt implements JsonConverter<int, Object?> {
  const LenientInt();

  @override
  int fromJson(Object? json) => switch (json) {
    final int value => value,
    final num value => value.toInt(),
    final String value => int.tryParse(value.trim()) ?? 0,
    _ => 0,
  };

  @override
  Object? toJson(int value) => value;
}
