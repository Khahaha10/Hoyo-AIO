import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';

class DynamicSecret {
  DynamicSecret({DateTime Function()? now, Random? random})
    : _now = now ?? DateTime.now,
      _random = random ?? Random.secure();

  static const _alphabet = 'abcdefghijklmnopqrstuvwxyz';
  static const _randomLength = 6;

  final DateTime Function() _now;
  final Random _random;

  String generate() {
    final timestamp = _now().millisecondsSinceEpoch ~/ 1000;
    final random = String.fromCharCodes([
      for (var i = 0; i < _randomLength; i++)
        _alphabet.codeUnitAt(_random.nextInt(_alphabet.length)),
    ]);
    return compute(timestamp: timestamp, random: random);
  }

  static String compute({
    required int timestamp,
    required String random,
    String salt = HoyolabConfig.dsSalt,
  }) {
    final digest = md5.convert(
      utf8.encode('salt=$salt&t=$timestamp&r=$random'),
    );
    return '$timestamp,$random,$digest';
  }
}
