import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/core/l10n/arb/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

Set<Object?> _placeholders(Object? meta) =>
    meta is Map && meta['placeholders'] is Map
    ? (meta['placeholders'] as Map).keys.toSet()
    : <Object?>{};

void main() {
  final en = _arb('en');
  final id = _arb('id');

  test('en and id have exactly the same message keys', () {
    expect(_messageKeys(id).difference(_messageKeys(en)), isEmpty);
    expect(_messageKeys(en).difference(_messageKeys(id)), isEmpty);
  });

  test('id uses every placeholder declared in en', () {
    final missing = <String>[];
    for (final key in _messageKeys(en)) {
      final text = id[key] as String? ?? '';
      for (final name in _placeholders(en['@$key'])) {
        if (!RegExp('\\{$name[,}\\s]').hasMatch(text)) {
          missing.add('$key.$name');
        }
      }
    }
    expect(missing, isEmpty);
  });

  test('id declares no placeholder names that en lacks', () {
    final extra = <String>[];
    for (final key in id.keys.where((k) => k.startsWith('@'))) {
      final enNames = _placeholders(en[key]);
      for (final name in _placeholders(id[key])) {
        if (!enNames.contains(name)) extra.add('$key.$name');
      }
    }
    expect(extra, isEmpty);
  });
}
