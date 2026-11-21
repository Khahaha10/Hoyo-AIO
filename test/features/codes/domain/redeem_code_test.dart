import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/codes/domain/redeem_code.dart';

void main() {
  final now = DateTime(2026, 11, 21, 12);

  RedeemCode code({bool active = true, DateTime? expiresAt}) => RedeemCode(
    game: Game.genshin,
    code: 'CODE',
    rewards: const [],
    active: active,
    firstSeenAt: now,
    unread: false,
    expiresAt: expiresAt,
  );

  final cases = <(String, RedeemCode, bool)>[
    ('active without expiry', code(), false),
    (
      'active with future expiry',
      code(expiresAt: now.add(const Duration(minutes: 1))),
      false,
    ),
    ('active with expiry exactly now', code(expiresAt: now), false),
    (
      'active with past expiry',
      code(expiresAt: now.subtract(const Duration(minutes: 1))),
      true,
    ),
    ('no longer listed', code(active: false), true),
  ];
  for (final (name, value, expired) in cases) {
    test('isExpiredAt: $name is $expired', () {
      expect(value.isExpiredAt(now), expired);
    });
  }
}
