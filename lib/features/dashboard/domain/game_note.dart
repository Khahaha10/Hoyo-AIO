import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/dashboard/domain/expedition.dart';
import 'package:hoyo_aio/features/dashboard/domain/stamina.dart';
import 'package:hoyo_aio/features/dashboard/domain/task_progress.dart';

part 'game_note.freezed.dart';

enum VideoStoreState { closed, open, revenueReady }

@freezed
sealed class GameNote with _$GameNote {
  const factory GameNote.genshin({
    required DateTime fetchedAt,
    required Stamina resin,
    required Stamina realmCurrency,
    required TaskProgress commissions,
    required bool commissionBonusClaimed,
    required TaskProgress weeklyBossDiscountsLeft,
    required DateTime? transformerReadyAt,
    required List<Expedition> expeditions,
    required int maxExpeditions,
  }) = GenshinNote;

  const factory GameNote.starRail({
    required DateTime fetchedAt,
    required Stamina trailblazePower,
    required TaskProgress reservedPower,
    required TaskProgress dailyTraining,
    required TaskProgress echoOfWarLeft,
    required TaskProgress simulatedUniverse,
    required List<Expedition> assignments,
    required int maxAssignments,
  }) = StarRailNote;

  const factory GameNote.zzz({
    required DateTime fetchedAt,
    required Stamina battery,
    required TaskProgress engagement,
    required bool scratchCardDone,
    required VideoStoreState videoStore,
    required TaskProgress? bountyCommission,
    required TaskProgress? weeklyProgress,
  }) = ZzzNote;

  const GameNote._();

  Game get game => switch (this) {
    GenshinNote() => Game.genshin,
    StarRailNote() => Game.starRail,
    ZzzNote() => Game.zzz,
  };

  Stamina get stamina => switch (this) {
    GenshinNote(:final resin) => resin,
    StarRailNote(:final trailblazePower) => trailblazePower,
    ZzzNote(:final battery) => battery,
  };
}
