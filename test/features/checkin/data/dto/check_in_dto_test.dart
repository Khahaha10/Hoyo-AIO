import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/checkin/data/dto/check_in_dto.dart';

import '../../_support/check_in_fixtures.dart';

void main() {
  test('CheckInInfoDto reads snake_case fields', () {
    final dto = CheckInInfoDto.fromJson(
      infoJson(totalSignDay: 7, isSign: true, signCntMissed: '3'),
    );

    expect(dto.totalSignDay, 7);
    expect(dto.isSign, isTrue);
    expect(dto.signCntMissed, 3);
    expect(dto.today, '2026-11-05');
  });

  test('CheckInInfoDto falls back to defaults for missing fields', () {
    final dto = CheckInInfoDto.fromJson(const {});

    expect(dto, const CheckInInfoDto());
  });

  for (final game in Game.values) {
    test('CheckInHomeDto parses the ${game.name} reward list', () {
      final dto = CheckInHomeDto.fromJson(homeJson(game, days: 3));

      expect(dto.month, 11);
      expect(dto.awards.map((a) => a.name), rewardNames[game]);
      expect(dto.awards.map((a) => a.cnt), [10, 20, 30]);
    });
  }

  test('CheckInAwardPageDto parses records with string counts', () {
    final dto = CheckInAwardPageDto.fromJson(
      awardJson([('Primogem', 60, '2026-11-01 06:00:00')]),
    );

    expect(dto.total, 1);
    expect(
      dto.list.single,
      const CheckInAwardRecordDto(
        name: 'Primogem',
        cnt: 60,
        createdAt: '2026-11-01 06:00:00',
      ),
    );
  });

  group('CheckInSignDto.needsCaptcha', () {
    test('is false for a clean response', () {
      expect(CheckInSignDto.fromJson(signJson()).needsCaptcha, isFalse);
    });

    test('is true when is_risk is set', () {
      expect(
        CheckInSignDto.fromJson(signJson(isRisk: true)).needsCaptcha,
        isTrue,
      );
    });

    test('is true when the geetest result is risky', () {
      expect(
        CheckInSignDto.fromJson(signJson(gtRisk: true)).needsCaptcha,
        isTrue,
      );
    });

    test('is false when the geetest result is clean', () {
      expect(
        CheckInSignDto.fromJson(signJson(gtRisk: false)).needsCaptcha,
        isFalse,
      );
    });
  });
}
