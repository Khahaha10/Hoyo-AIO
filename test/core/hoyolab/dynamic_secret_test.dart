import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/hoyolab/dynamic_secret.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';

void main() {
  group('DynamicSecret.compute', () {
    test('matches independently computed md5 vectors', () {
      expect(
        DynamicSecret.compute(timestamp: 1700000000, random: 'abcdef'),
        '1700000000,abcdef,a22d61645a7aabcbb80a890625fce64c',
      );
      expect(
        DynamicSecret.compute(timestamp: 1763634480, random: 'qwerty'),
        '1763634480,qwerty,4a16f61ab92fcf1fd7efe8ef1ae4d341',
      );
    });

    test('uses the overseas salt from config by default', () {
      expect(HoyolabConfig.dsSalt, '6cqshh5dhw73bzxn20oexa9k516chk7s');
      expect(
        DynamicSecret.compute(
          timestamp: 1700000000,
          random: 'abcdef',
          salt: 'other',
        ),
        isNot(endsWith('a22d61645a7aabcbb80a890625fce64c')),
      );
    });
  });

  group('DynamicSecret.generate', () {
    test('uses the injected clock in whole seconds', () {
      final ds = DynamicSecret(
        now: () => DateTime.fromMillisecondsSinceEpoch(1700000000999),
        random: Random(1),
      );
      expect(ds.generate().split(',').first, '1700000000');
    });

    test('random part is 6 lowercase letters and the hash is 32 hex', () {
      final ds = DynamicSecret(random: Random(42));
      for (var i = 0; i < 50; i++) {
        final parts = ds.generate().split(',');
        expect(parts, hasLength(3));
        expect(parts[1], matches(RegExp(r'^[a-z]{6}$')));
        expect(parts[2], matches(RegExp(r'^[0-9a-f]{32}$')));
      }
    });

    test('is consistent with compute for the same inputs', () {
      final ds = DynamicSecret(
        now: () => DateTime.fromMillisecondsSinceEpoch(1700000000000),
        random: Random(7),
      );
      final parts = ds.generate().split(',');
      expect(
        DynamicSecret.compute(timestamp: 1700000000, random: parts[1]),
        parts.join(','),
      );
    });
  });
}
