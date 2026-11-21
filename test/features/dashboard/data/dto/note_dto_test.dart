import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/dashboard/data/dto/genshin_note_dto.dart';
import 'package:hoyo_aio/features/dashboard/data/dto/star_rail_note_dto.dart';
import 'package:hoyo_aio/features/dashboard/data/dto/zzz_note_dto.dart';

import '../../_support/dashboard_fakes.dart';

void main() {
  group('GenshinNoteDto', () {
    test('parses the fixture including string numbers', () {
      final dto = GenshinNoteDto.fromJson(loadNoteFixture(Game.genshin));

      expect(dto.currentResin, 142);
      expect(dto.maxResin, 200);
      expect(dto.resinRecoveryTime, 11520);
      expect(dto.finishedTaskNum, 3);
      expect(dto.totalTaskNum, 4);
      expect(dto.isExtraTaskRewardReceived, isFalse);
      expect(dto.remainResinDiscountNum, 2);
      expect(dto.resinDiscountNumLimit, 3);
      expect(dto.currentHomeCoin, 1840);
      expect(dto.maxHomeCoin, 2400);
      expect(dto.homeCoinRecoveryTime, 32400);
      expect(dto.maxExpeditionNum, 5);
      expect(dto.expeditions, hasLength(2));
      expect(dto.expeditions.first.status, 'Finished');
      expect(dto.expeditions.last.remainedTime, 8040);
      expect(dto.transformer?.obtained, isTrue);
      expect(dto.transformer?.recoveryTime?.day, 4);
      expect(dto.transformer?.recoveryTime?.hour, 6);
      expect(dto.transformer?.recoveryTime?.reached, isFalse);
    });

    test('falls back to defaults when every field is missing', () {
      final dto = GenshinNoteDto.fromJson(const {});

      expect(dto.currentResin, 0);
      expect(dto.expeditions, isEmpty);
      expect(dto.transformer, isNull);
    });

    test('maps null, double and junk numbers leniently', () {
      final dto = GenshinNoteDto.fromJson(const {
        'current_resin': null,
        'max_resin': 200.0,
        'resin_recovery_time': 'abc',
        'current_home_coin': ' 12 ',
        'expeditions': [
          {'status': 'Ongoing', 'remained_time': true},
        ],
      });

      expect(dto.currentResin, 0);
      expect(dto.maxResin, 200);
      expect(dto.resinRecoveryTime, 0);
      expect(dto.currentHomeCoin, 12);
      expect(dto.expeditions.single.remainedTime, 0);
    });
  });

  group('StarRailNoteDto', () {
    test('parses the fixture', () {
      final dto = StarRailNoteDto.fromJson(loadNoteFixture(Game.starRail));

      expect(dto.currentStamina, 168);
      expect(dto.maxStamina, 240);
      expect(dto.staminaRecoverTime, 25920);
      expect(dto.staminaFullTs, 1763660400);
      expect(dto.currentTs, 1763634480);
      expect(dto.currentReserveStamina, 1236);
      expect(dto.totalExpeditionNum, 4);
      expect(dto.expeditions.last.name, 'Assignment name');
      expect(dto.expeditions.last.remainingTime, 13200);
      expect(dto.currentTrainScore, 400);
      expect(dto.maxRogueScore, 14000);
      expect(dto.weeklyCocoonCnt, 1);
      expect(dto.weeklyCocoonLimit, 3);
    });

    test('falls back to defaults when fields are missing', () {
      final dto = StarRailNoteDto.fromJson(const {
        'expeditions': [<String, dynamic>{}],
      });

      expect(dto.currentStamina, 0);
      expect(dto.expeditions.single.name, isNull);
      expect(dto.expeditions.single.status, '');
    });
  });

  group('ZzzNoteDto', () {
    test('parses the fixture', () {
      final dto = ZzzNoteDto.fromJson(loadNoteFixture(Game.zzz));

      expect(dto.energy.progress.current, 186);
      expect(dto.energy.progress.max, 240);
      expect(dto.energy.restore, 19440);
      expect(dto.vitality.current, 300);
      expect(dto.vhsSale?.saleState, 'SaleStateDoing');
      expect(dto.cardSign, 'CardSignDone');
      expect(dto.bountyCommission?.num, 2);
      expect(dto.bountyCommission?.total, 4);
      expect(dto.weeklyTask?.maxPoint, 1300);
    });

    test('falls back to defaults when optional blocks are missing', () {
      final dto = ZzzNoteDto.fromJson(const {});

      expect(dto.energy.progress.max, 0);
      expect(dto.vitality.current, 0);
      expect(dto.vhsSale, isNull);
      expect(dto.cardSign, isNull);
      expect(dto.bountyCommission, isNull);
      expect(dto.weeklyTask, isNull);
    });
  });
}
