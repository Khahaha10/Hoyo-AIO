import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/features/dashboard/data/dto/genshin_note_dto.dart';
import 'package:hoyo_aio/features/dashboard/data/dto/star_rail_note_dto.dart';
import 'package:hoyo_aio/features/dashboard/data/dto/zzz_note_dto.dart';
import 'package:hoyo_aio/features/dashboard/data/notes_mapper.dart';
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';
import 'package:hoyo_aio/features/dashboard/domain/task_progress.dart';

import '../_support/dashboard_fakes.dart';

void main() {
  final t0 = fixedNow;
  Duration s(int seconds) => Duration(seconds: seconds);

  group('genshin', () {
    test('maps the fixture to a GenshinNote', () {
      final note = NotesMapper.fromJson(
        Game.genshin,
        loadNoteFixture(Game.genshin),
        t0,
      ) as GenshinNote;

      expect(note.fetchedAt, t0);
      expect(note.resin.current, 142);
      expect(note.resin.max, 200);
      expect(note.resin.recoveryInterval, const Duration(minutes: 8));
      expect(note.resin.fullAt, t0.add(s(11520)));
      expect(note.realmCurrency.current, 1840);
      expect(note.realmCurrency.fullAt, t0.add(s(32400)));
      expect(
        note.realmCurrency.recoveryInterval,
        const Duration(microseconds: 32400 * 1000000 ~/ 560),
      );
      expect(note.commissions, const TaskProgress(done: 3, total: 4));
      expect(note.commissionBonusClaimed, isFalse);
      expect(
        note.weeklyBossDiscountsLeft,
        const TaskProgress(done: 2, total: 3),
      );
      expect(
        note.transformerReadyAt,
        t0.add(const Duration(days: 4, hours: 6)),
      );
      expect(note.expeditions.map((e) => e.doneAt), [t0, t0.add(s(8040))]);
      expect(note.maxExpeditions, 5);
    });

    test('marks a reached transformer as ready now', () {
      const dto = GenshinNoteDto(
        transformer: GenshinTransformerDto(
          obtained: true,
          recoveryTime: GenshinTransformerTimeDto(reached: true),
        ),
      );

      expect(NotesMapper.genshin(dto, t0).transformerReadyAt, t0);
    });

    test('has no transformer time when it is not obtained or missing', () {
      const notObtained = GenshinNoteDto(
        transformer: GenshinTransformerDto(
          recoveryTime: GenshinTransformerTimeDto(day: 1),
        ),
      );
      const noTime = GenshinNoteDto(
        transformer: GenshinTransformerDto(obtained: true),
      );

      expect(NotesMapper.genshin(notObtained, t0).transformerReadyAt, isNull);
      expect(NotesMapper.genshin(noTime, t0).transformerReadyAt, isNull);
      expect(
        NotesMapper.genshin(const GenshinNoteDto(), t0).transformerReadyAt,
        isNull,
      );
    });

    test('full realm currency has no averaged interval', () {
      const dto = GenshinNoteDto(currentHomeCoin: 2400, maxHomeCoin: 2400);

      final coins = NotesMapper.genshin(dto, t0).realmCurrency;

      expect(coins.recoveryInterval, Duration.zero);
      expect(coins.reportedFullAt, isNull);
    });

    test('clamps a negative remaining time to now', () {
      const dto = GenshinNoteDto(
        expeditions: [
          GenshinExpeditionDto(status: 'Ongoing', remainedTime: -5),
        ],
      );

      expect(NotesMapper.genshin(dto, t0).expeditions.single.doneAt, t0);
    });

    test('resin without a reported time is extrapolated from the interval', () {
      const dto = GenshinNoteDto(currentResin: 190, maxResin: 200);

      final resin = NotesMapper.genshin(dto, t0).resin;

      expect(resin.reportedFullAt, isNull);
      expect(resin.fullAt, t0.add(const Duration(minutes: 80)));
    });
  });

  group('starRail', () {
    test('maps the fixture to a StarRailNote', () {
      final note = NotesMapper.fromJson(
        Game.starRail,
        loadNoteFixture(Game.starRail),
        t0,
      ) as StarRailNote;

      expect(note.trailblazePower.current, 168);
      expect(note.trailblazePower.fullAt, t0.add(s(25920)));
      expect(
        note.reservedPower,
        const TaskProgress(
          done: 1236,
          total: HoyolabConfig.starRailReservedPowerMax,
        ),
      );
      expect(note.dailyTraining, const TaskProgress(done: 400, total: 500));
      expect(note.echoOfWarLeft, const TaskProgress(done: 1, total: 3));
      expect(
        note.simulatedUniverse,
        const TaskProgress(done: 9800, total: 14000),
      );
      expect(note.assignments.map((e) => e.doneAt), [t0, t0.add(s(13200))]);
      expect(note.assignments.first.name, 'Assignment name');
      expect(note.maxAssignments, 4);
    });

    test('uses the server timestamps over the recover time', () {
      const dto = StarRailNoteDto(
        currentStamina: 10,
        maxStamina: 240,
        staminaRecoverTime: 999,
        staminaFullTs: 1000,
        currentTs: 400,
      );

      expect(
        NotesMapper.starRail(dto, t0).trailblazePower.fullAt,
        t0.add(s(600)),
      );
    });

    test('falls back to the recover time without timestamps', () {
      const dto = StarRailNoteDto(
        currentStamina: 10,
        maxStamina: 240,
        staminaRecoverTime: 999,
      );

      expect(
        NotesMapper.starRail(dto, t0).trailblazePower.fullAt,
        t0.add(s(999)),
      );
    });
  });

  group('zzz', () {
    test('maps the fixture to a ZzzNote', () {
      final note = NotesMapper.fromJson(
        Game.zzz,
        loadNoteFixture(Game.zzz),
        t0,
      ) as ZzzNote;

      expect(note.battery.current, 186);
      expect(note.battery.fullAt, t0.add(s(19440)));
      expect(note.engagement, const TaskProgress(done: 300, total: 400));
      expect(note.scratchCardDone, isTrue);
      expect(note.videoStore, VideoStoreState.open);
      expect(note.bountyCommission, const TaskProgress(done: 2, total: 4));
      expect(note.weeklyProgress, const TaskProgress(done: 0, total: 1300));
    });

    final videoCases = <(String?, VideoStoreState)>[
      ('SaleStateDone', VideoStoreState.revenueReady),
      ('SaleStateNo', VideoStoreState.closed),
      (null, VideoStoreState.closed),
    ];
    for (final (state, expected) in videoCases) {
      test('maps video store $state to ${expected.name}', () {
        final dto = ZzzNoteDto(vhsSale: ZzzVhsSaleDto(saleState: state));
        expect(NotesMapper.zzz(dto, t0).videoStore, expected);
      });
    }

    test('hides empty bounty and weekly blocks', () {
      const dto = ZzzNoteDto(
        cardSign: 'CardSignNo',
        bountyCommission: ZzzCountDto(),
        weeklyTask: ZzzWeeklyTaskDto(),
      );

      final note = NotesMapper.zzz(dto, t0);

      expect(note.scratchCardDone, isFalse);
      expect(note.bountyCommission, isNull);
      expect(note.weeklyProgress, isNull);
    });
  });

  test('rejects HI3 because it has no notes', () {
    expect(
      () => NotesMapper.fromJson(Game.hi3, const {}, t0),
      throwsArgumentError,
    );
  });
}
