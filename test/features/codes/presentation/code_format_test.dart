import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/codes/presentation/code_format.dart';

void main() {
  group('code payload', () {
    test('round-trips game and code', () {
      final payload = codePayload(Game.starRail, 'ABC 123');

      expect(parseCodePayload(payload), (Game.starRail, 'ABC 123'));
    });

    final rejected = {
      'null': null,
      'other host': 'hoyoaio://dashboard?game=genshin&code=A',
      'unknown game': 'hoyoaio://code?game=nope&code=A',
      'missing code': 'hoyoaio://code?game=genshin',
      'empty code': 'hoyoaio://code?game=genshin&code=',
    };
    for (final MapEntry(key: name, value: payload) in rejected.entries) {
      test('rejects $name', () {
        expect(parseCodePayload(payload), isNull);
      });
    }
  });

  group('codeRewards', () {
    test('formats amounts', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(l10n.codeRewards([60, 10000]), '×60 · ×10,000');
      expect(l10n.codeRewards([]), 'Rewards not listed');
    });
  });
}
