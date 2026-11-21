import 'package:flutter/foundation.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';

@immutable
class HoyolabCookie {
  const HoyolabCookie._(this.values);

  factory HoyolabCookie.parse(String raw) {
    final values = <String, String>{};
    for (final part in raw.split(';')) {
      final separator = part.indexOf('=');
      if (separator <= 0) continue;
      final key = part.substring(0, separator).trim();
      final value = _unquote(part.substring(separator + 1).trim());
      if (value.isEmpty || !HoyolabConfig.cookieKeys.contains(key)) continue;
      values[key] = value;
    }
    return HoyolabCookie._(Map.unmodifiable(values));
  }

  final Map<String, String> values;

  String? get hoyolabUid {
    for (final key in HoyolabConfig.cookieUidKeys) {
      final value = values[key];
      if (value != null && int.tryParse(value) != null) return value;
    }
    return null;
  }

  bool get hasLoginToken =>
      HoyolabConfig.cookieTokenKeys.any(values.containsKey);

  bool get isUsable => hoyolabUid != null && hasLoginToken;

  int get keyCount => values.length;

  String serialize() =>
      values.entries.map((e) => '${e.key}=${e.value}').join('; ');

  static String _unquote(String value) =>
      value.length >= 2 && value.startsWith('"') && value.endsWith('"')
      ? value.substring(1, value.length - 1)
      : value;

  @override
  bool operator ==(Object other) =>
      other is HoyolabCookie && other.serialize() == serialize();

  @override
  int get hashCode => serialize().hashCode;

  @override
  String toString() => 'HoyolabCookie(keys: ${values.keys.join(', ')})';
}
