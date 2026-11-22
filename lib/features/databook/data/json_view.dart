class Json {
  const Json(this.raw);

  final Object? raw;

  Json operator [](Object key) => Json(switch ((raw, key)) {
    (final Map<Object?, Object?> map, final String name) => map[name],
    (final List<Object?> list, final int index)
        when index >= 0 && index < list.length =>
      list[index],
    _ => null,
  });

  bool get exists => raw != null;

  bool get isMap => raw is Map;

  List<Json> get items => switch (raw) {
    final List<Object?> list => [for (final item in list) Json(item)],
    _ => const [],
  };

  int? get intOrNull => switch (raw) {
    final num value => value.toInt(),
    final String text => int.tryParse(text),
    _ => null,
  };

  int get intValue => intOrNull ?? 0;

  String? get stringOrNull => switch (raw) {
    final String text when text.isNotEmpty => text,
    final num value => '$value',
    _ => null,
  };

  String get stringValue => stringOrNull ?? '';

  bool get boolValue => raw == true;
}
