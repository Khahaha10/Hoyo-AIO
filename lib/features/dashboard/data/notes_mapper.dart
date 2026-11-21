import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/features/dashboard/data/dto/genshin_note_dto.dart';
import 'package:hoyo_aio/features/dashboard/data/dto/star_rail_note_dto.dart';
import 'package:hoyo_aio/features/dashboard/data/dto/zzz_note_dto.dart';
import 'package:hoyo_aio/features/dashboard/domain/expedition.dart';
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';
import 'package:hoyo_aio/features/dashboard/domain/stamina.dart';
import 'package:hoyo_aio/features/dashboard/domain/task_progress.dart';

abstract final class NotesMapper {
  static const _finished = 'Finished';
  static const _cardSignDone = 'CardSignDone';
  static const _saleDoing = 'SaleStateDoing';
  static const _saleDone = 'SaleStateDone';

  static GameNote fromJson(
    Game game,
    Map<String, dynamic> json,
    DateTime fetchedAt,
  ) => switch (game) {
    Game.genshin => genshin(GenshinNoteDto.fromJson(json), fetchedAt),
    Game.starRail => starRail(StarRailNoteDto.fromJson(json), fetchedAt),
    Game.zzz => zzz(ZzzNoteDto.fromJson(json), fetchedAt),
    Game.hi3 => throw ArgumentError.value(game, 'game', 'has no notes'),
  };

  static GenshinNote genshin(GenshinNoteDto dto, DateTime fetchedAt) =>
      GenshinNote(
        fetchedAt: fetchedAt,
        resin: _stamina(
          Game.genshin,
          dto.currentResin,
          dto.maxResin,
          dto.resinRecoveryTime,
          fetchedAt,
        ),
        realmCurrency: _averagedStamina(
          dto.currentHomeCoin,
          dto.maxHomeCoin,
          dto.homeCoinRecoveryTime,
          fetchedAt,
        ),
        commissions: TaskProgress(
          done: dto.finishedTaskNum,
          total: dto.totalTaskNum,
        ),
        commissionBonusClaimed: dto.isExtraTaskRewardReceived,
        weeklyBossDiscountsLeft: TaskProgress(
          done: dto.remainResinDiscountNum,
          total: dto.resinDiscountNumLimit,
        ),
        transformerReadyAt: _transformerReadyAt(dto.transformer, fetchedAt),
        expeditions: [
          for (final e in dto.expeditions)
            Expedition(
              doneAt: e.status == _finished
                  ? fetchedAt
                  : _after(fetchedAt, e.remainedTime),
            ),
        ],
        maxExpeditions: dto.maxExpeditionNum,
      );

  static StarRailNote starRail(StarRailNoteDto dto, DateTime fetchedAt) {
    final serverRemaining = dto.staminaFullTs - dto.currentTs;
    final secondsToFull = dto.staminaFullTs > 0 && dto.currentTs > 0
        ? serverRemaining
        : dto.staminaRecoverTime;
    return StarRailNote(
      fetchedAt: fetchedAt,
      trailblazePower: _stamina(
        Game.starRail,
        dto.currentStamina,
        dto.maxStamina,
        secondsToFull,
        fetchedAt,
      ),
      reservedPower: TaskProgress(
        done: dto.currentReserveStamina,
        total: HoyolabConfig.starRailReservedPowerMax,
      ),
      dailyTraining: TaskProgress(
        done: dto.currentTrainScore,
        total: dto.maxTrainScore,
      ),
      echoOfWarLeft: TaskProgress(
        done: dto.weeklyCocoonCnt,
        total: dto.weeklyCocoonLimit,
      ),
      simulatedUniverse: TaskProgress(
        done: dto.currentRogueScore,
        total: dto.maxRogueScore,
      ),
      assignments: [
        for (final e in dto.expeditions)
          Expedition(
            name: e.name,
            doneAt: e.status == _finished
                ? fetchedAt
                : _after(fetchedAt, e.remainingTime),
          ),
      ],
      maxAssignments: dto.totalExpeditionNum,
    );
  }

  static ZzzNote zzz(ZzzNoteDto dto, DateTime fetchedAt) => ZzzNote(
    fetchedAt: fetchedAt,
    battery: _stamina(
      Game.zzz,
      dto.energy.progress.current,
      dto.energy.progress.max,
      dto.energy.restore,
      fetchedAt,
    ),
    engagement: TaskProgress(
      done: dto.vitality.current,
      total: dto.vitality.max,
    ),
    scratchCardDone: dto.cardSign == _cardSignDone,
    videoStore: switch (dto.vhsSale?.saleState) {
      _saleDoing => VideoStoreState.open,
      _saleDone => VideoStoreState.revenueReady,
      _ => VideoStoreState.closed,
    },
    bountyCommission: switch (dto.bountyCommission) {
      final b? when b.total > 0 => TaskProgress(done: b.num, total: b.total),
      _ => null,
    },
    weeklyProgress: switch (dto.weeklyTask) {
      final w? when w.maxPoint > 0 => TaskProgress(
        done: w.curPoint,
        total: w.maxPoint,
      ),
      _ => null,
    },
  );

  static Stamina _stamina(
    Game game,
    int current,
    int max,
    int secondsToFull,
    DateTime fetchedAt,
  ) => Stamina(
    current: current,
    max: max,
    fetchedAt: fetchedAt,
    recoveryInterval: HoyolabConfig.staminaRecovery[game] ?? Duration.zero,
    reportedFullAt: secondsToFull > 0 ? _after(fetchedAt, secondsToFull) : null,
  );

  static Stamina _averagedStamina(
    int current,
    int max,
    int secondsToFull,
    DateTime fetchedAt,
  ) {
    final missing = max - current;
    final canAverage = missing > 0 && secondsToFull > 0;
    return Stamina(
      current: current,
      max: max,
      fetchedAt: fetchedAt,
      recoveryInterval: canAverage
          ? Duration(microseconds: secondsToFull * 1000000 ~/ missing)
          : Duration.zero,
      reportedFullAt: canAverage ? _after(fetchedAt, secondsToFull) : null,
    );
  }

  static DateTime? _transformerReadyAt(
    GenshinTransformerDto? dto,
    DateTime fetchedAt,
  ) {
    final time = dto?.recoveryTime;
    if (dto == null || !dto.obtained || time == null) return null;
    if (time.reached) return fetchedAt;
    return fetchedAt.add(
      Duration(
        days: time.day,
        hours: time.hour,
        minutes: time.minute,
        seconds: time.second,
      ),
    );
  }

  static DateTime _after(DateTime from, int seconds) =>
      from.add(Duration(seconds: seconds < 0 ? 0 : seconds));
}
