import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _configFile = 'lib/core/hoyolab/hoyolab_config.dart';

final _forbidden = <String, RegExp>{
  'HoYoLAB/HoYoverse host': RegExp(r'hoyolab\.com|hoyoverse\.com|mihoyo\.com'),
  'act_id': RegExp(r'e20\d{13}'),
  'DS salt': RegExp('6cqshh5dhw73bzxn20oexa9k516chk7s'),
  'server id': RegExp(
    r'\b(os_(asia|usa|euro|cht)|prod_official_\w+|prod_gf_\w+)\b',
  ),
};

void main() {
  test('API literals live only in hoyolab_config.dart', () {
    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('.g.dart'))
        .where((f) => !f.path.endsWith('.freezed.dart'))
        .where((f) => f.path.replaceAll(r'\', '/') != _configFile);
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final MapEntry(key: what, value: pattern) in _forbidden.entries) {
        if (pattern.hasMatch(source)) offenders.add('${file.path}: $what');
      }
    }
    expect(offenders, isEmpty);
  });

  test('the config file itself exists and holds the salt', () {
    expect(File(_configFile).readAsStringSync(), contains('6cqshh5dhw73'));
  });
}
