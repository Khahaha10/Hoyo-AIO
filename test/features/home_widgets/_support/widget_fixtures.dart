import 'dart:async';

import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_history_repository.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_record.dart';
import 'package:hoyo_aio/features/dashboard/domain/expedition.dart';
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';
import 'package:hoyo_aio/features/dashboard/domain/note_result.dart';
import 'package:hoyo_aio/features/dashboard/domain/notes_repository.dart';
import 'package:hoyo_aio/features/dashboard/domain/stamina.dart';
import 'package:hoyo_aio/features/dashboard/domain/task_progress.dart';
import 'package:hoyo_aio/features/home_widgets/domain/home_widget_repositories.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot_builder.dart';

final fetchedAt = DateTime(2026, 11, 21, 10);

const testAccountId = '900000001';

SavedRole role(int id, Game game, {String accountId = testAccountId}) =>
    SavedRole(
      id: id,
      accountId: accountId,
      game: game,
      uid: '80000000$id',
      server: 'os_asia',
      nickname: 'Tester$id',
      level: 60,
      enabled: true,
    );

final genshinRole = role(1, Game.genshin);
final starRailRole = role(2, Game.starRail);
final zzzRole = role(3, Game.zzz);

final genshinNote = GameNote.genshin(
  fetchedAt: fetchedAt,
  resin: Stamina(
    current: 100,
    max: 200,
    fetchedAt: fetchedAt,
    recoveryInterval: const Duration(minutes: 8),
  ),
  realmCurrency: Stamina(
    current: 1200,
    max: 2400,
    fetchedAt: fetchedAt,
    recoveryInterval: const Duration(minutes: 3),
  ),
  commissions: const TaskProgress(done: 2, total: 4),
  commissionBonusClaimed: false,
  weeklyBossDiscountsLeft: const TaskProgress(done: 1, total: 3),
  transformerReadyAt: fetchedAt.add(const Duration(hours: 5)),
  expeditions: [
    Expedition(doneAt: fetchedAt.subtract(const Duration(minutes: 1))),
    Expedition(doneAt: fetchedAt.add(const Duration(hours: 2))),
    Expedition(doneAt: fetchedAt.add(const Duration(hours: 6))),
  ],
  maxExpeditions: 5,
);

final starRailNote = GameNote.starRail(
  fetchedAt: fetchedAt,
  trailblazePower: Stamina(
    current: 240,
    max: 240,
    fetchedAt: fetchedAt,
    recoveryInterval: const Duration(minutes: 6),
  ),
  reservedPower: const TaskProgress(done: 1000, total: 2400),
  dailyTraining: const TaskProgress(done: 500, total: 500),
  echoOfWarLeft: const TaskProgress(done: 3, total: 3),
  simulatedUniverse: const TaskProgress(done: 2000, total: 14000),
  assignments: const [],
  maxAssignments: 4,
);

final zzzNote = GameNote.zzz(
  fetchedAt: fetchedAt,
  battery: Stamina(
    current: 60,
    max: 240,
    fetchedAt: fetchedAt,
    recoveryInterval: const Duration(minutes: 6),
  ),
  engagement: const TaskProgress(done: 300, total: 400),
  scratchCardDone: true,
  videoStore: VideoStoreState.revenueReady,
  bountyCommission: const TaskProgress(done: 1, total: 4),
  weeklyProgress: null,
);

final allNotes = <(SavedRole, NoteResult)>[
  (genshinRole, NoteResult(note: genshinNote)),
  (starRailRole, NoteResult(note: starRailNote, isStale: true)),
  (zzzRole, NoteResult(note: zzzNote)),
];

const testLabels = {
  'resin': 'Original Resin',
  'realm': 'Realm',
  'commissions': 'Commissions',
  'weeklyBosses': 'Weekly Bosses',
  'transformer': 'Transformer',
  'expeditions': 'Expeditions',
  'full': 'Full',
  'ready': 'Ready',
  'done': 'Done',
  'app': 'HoYo AIO',
  'updated': 'Updated {time}',
  'checkedIn': 'Checked in to {done} of {total} games',
  'short.resin': 'Resin',
  'short.trailblazePower': 'Power',
  'short.battery': 'Battery',
  'game.genshin': 'Genshin',
  'game.starRail': 'Star Rail',
  'game.zzz': 'ZZZ',
  'videoStore.revenueReady': 'Revenue ready',
};

WidgetConfigSnapshot config({
  int widgetId = 7,
  String size = 'medium',
  int? roleId = 1,
  String theme = 'light',
  double opacity = 1,
  String accent = 'match',
  String fontSize = 'medium',
  List<String> visibleItems = const [],
}) => WidgetConfigSnapshot(
  widgetId: widgetId,
  size: size,
  roleId: roleId,
  theme: theme,
  opacity: opacity,
  accent: accent,
  fontSize: fontSize,
  visibleItems: visibleItems,
);

CheckInRecord record(Game game, CheckInResult result) => CheckInRecord(
  accountId: testAccountId,
  game: game,
  day: '2026-11-21',
  result: result,
  runAt: fetchedAt,
);

class FakeNotesRepository implements NotesRepository {
  FakeNotesRepository(this.byRole);

  final Map<int, NoteResult> byRole;

  @override
  Future<NoteResult?> cached(SavedRole role) async => byRole[role.id];

  @override
  Future<NoteResult> refresh(SavedRole role) async =>
      byRole[role.id] ?? (throw StateError('no note'));
}

class FakeCheckInHistory implements CheckInHistoryRepository {
  FakeCheckInHistory({this.records = const [], this.settings});

  final List<CheckInRecord> records;
  final AutoCheckInSettings? settings;
  final requestedDays = <String>[];

  @override
  Future<List<CheckInRecord>> recordsOn(String day) async {
    requestedDays.add(day);
    return records;
  }

  @override
  Stream<AutoCheckInSettings> watchSettings() =>
      settings == null ? const Stream.empty() : Stream.value(settings!);

  @override
  Stream<List<CheckInRun>> watchRuns({required int limit}) =>
      Stream.value(const []);

  @override
  Future<void> addAll(List<CheckInRecord> records) async {}

  @override
  Future<bool> hasRunOn(String day) async => false;

  @override
  Future<void> setGameEnabled(Game game, {required bool enabled}) async {}

  @override
  Future<void> setRunAtMinutes(int minutes) async {}
}

class FakeWidgetConfigRepository implements WidgetConfigRepository {
  FakeWidgetConfigRepository([List<WidgetConfigSnapshot> initial = const []])
    : configs = [...initial];

  final List<WidgetConfigSnapshot> configs;
  final saved = <(WidgetConfigSnapshot, String?)>[];
  final _changes = StreamController<List<WidgetConfigSnapshot>>.broadcast();

  @override
  Future<List<WidgetConfigSnapshot>> all() async => configs;

  @override
  Stream<List<WidgetConfigSnapshot>> watch() async* {
    yield configs;
    yield* _changes.stream;
  }

  @override
  Future<void> save(
    WidgetConfigSnapshot config, {
    required String? accountId,
  }) async {
    saved.add((config, accountId));
    configs
      ..removeWhere((c) => c.widgetId == config.widgetId)
      ..add(config);
    _changes.add([...configs]);
  }
}

class FakeHomeWidgetBridge implements HomeWidgetBridge {
  FakeHomeWidgetBridge({this.placedWidgets = const [], this.pinSupported = true});

  final List<PlacedWidget> placedWidgets;
  final bool pinSupported;
  final published = <WidgetSnapshot>[];
  final pinned = <HomeWidgetSize>[];

  @override
  Future<void> publish(WidgetSnapshot snapshot) async =>
      published.add(snapshot);

  @override
  Future<List<PlacedWidget>> placed() async => placedWidgets;

  @override
  Future<bool> canPin() async => pinSupported;

  @override
  Future<void> pin(HomeWidgetSize size) async => pinned.add(size);
}

WidgetSnapshot previewSnapshot({List<WidgetConfigSnapshot> widgets = const []}) =>
    WidgetSnapshotBuilder.build(
      notes: allNotes,
      checkInToday: [record(Game.genshin, CheckInResult.claimed)],
      day: '2026-11-21',
      checkInTotal: 3,
      widgets: widgets,
      labels: testLabels,
      now: fetchedAt,
    );
