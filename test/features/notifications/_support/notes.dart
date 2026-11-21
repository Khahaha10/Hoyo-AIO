import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/dashboard/domain/expedition.dart';
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';
import 'package:hoyo_aio/features/dashboard/domain/stamina.dart';
import 'package:hoyo_aio/features/dashboard/domain/task_progress.dart';

final fetchedAt = DateTime(2026, 11, 5, 10);

const _task = TaskProgress(done: 0, total: 4);

SavedRole noteRole(int id, Game game) => SavedRole(
  id: id,
  accountId: '800000001',
  game: game,
  uid: '80000000$id',
  server: 'os_asia',
  nickname: 'Tester $id',
  level: 60,
  enabled: true,
);

Stamina stamina({
  int current = 100,
  int max = 200,
  Duration interval = const Duration(minutes: 8),
}) => Stamina(
  current: current,
  max: max,
  fetchedAt: fetchedAt,
  recoveryInterval: interval,
);

GenshinNote genshinNote({
  Stamina? resin,
  Stamina? realmCurrency,
  DateTime? transformerReadyAt,
  List<Expedition> expeditions = const [],
}) => GameNote.genshin(
  fetchedAt: fetchedAt,
  resin: resin ?? stamina(),
  realmCurrency:
      realmCurrency ??
      stamina(current: 1000, max: 2400, interval: const Duration(minutes: 3)),
  commissions: _task,
  commissionBonusClaimed: false,
  weeklyBossDiscountsLeft: const TaskProgress(done: 3, total: 3),
  transformerReadyAt: transformerReadyAt,
  expeditions: expeditions,
  maxExpeditions: 5,
) as GenshinNote;

StarRailNote starRailNote({
  Stamina? power,
  List<Expedition> assignments = const [],
}) => GameNote.starRail(
  fetchedAt: fetchedAt,
  trailblazePower:
      power ?? stamina(max: 240, interval: const Duration(minutes: 6)),
  reservedPower: const TaskProgress(done: 0, total: 2400),
  dailyTraining: const TaskProgress(done: 100, total: 500),
  echoOfWarLeft: const TaskProgress(done: 3, total: 3),
  simulatedUniverse: const TaskProgress(done: 0, total: 14000),
  assignments: assignments,
  maxAssignments: 4,
) as StarRailNote;

ZzzNote zzzNote({Stamina? battery}) => GameNote.zzz(
  fetchedAt: fetchedAt,
  battery: battery ?? stamina(max: 240, interval: const Duration(minutes: 6)),
  engagement: const TaskProgress(done: 100, total: 400),
  scratchCardDone: false,
  videoStore: VideoStoreState.open,
  bountyCommission: null,
  weeklyProgress: null,
) as ZzzNote;
