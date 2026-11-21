import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_record.dart';
import 'package:hoyo_aio/features/dashboard/domain/expedition.dart';
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';
import 'package:hoyo_aio/features/dashboard/domain/note_result.dart';
import 'package:hoyo_aio/features/dashboard/domain/stamina.dart';
import 'package:hoyo_aio/features/dashboard/domain/task_progress.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot.dart';

abstract final class WidgetSnapshotBuilder {
  static const version = 1;

  static WidgetSnapshot build({
    required List<(SavedRole, NoteResult)> notes,
    required List<CheckInRecord> checkInToday,
    required String day,
    required int checkInTotal,
    required List<WidgetConfigSnapshot> widgets,
    required Map<String, String> labels,
    required DateTime now,
  }) => WidgetSnapshot(
    version: version,
    generatedAt: now.toUtc(),
    roles: [for (final (role, result) in notes) _role(role, result)],
    checkIn: WidgetCheckIn(
      day: day,
      done: {
        for (final record in checkInToday)
          if (record.isSuccess) record.game,
      }.length,
      total: checkInTotal,
    ),
    widgets: widgets,
    labels: labels,
  );

  static WidgetRoleSnapshot _role(SavedRole role, NoteResult result) {
    final note = result.note;
    return WidgetRoleSnapshot(
      roleId: role.id,
      game: role.game,
      uid: role.uid,
      name: role.nickname,
      fetchedAt: note.fetchedAt.toUtc(),
      stale: result.isStale,
      stamina: _stamina(_staminaKey(note), note.stamina),
      items: _items(note),
    );
  }

  static String _staminaKey(GameNote note) => switch (note) {
    GenshinNote() => 'resin',
    StarRailNote() => 'trailblazePower',
    ZzzNote() => 'battery',
  };

  static WidgetStamina _stamina(String key, Stamina stamina) => WidgetStamina(
    key: key,
    current: stamina.current,
    max: stamina.max,
    fetchedAt: stamina.fetchedAt.toUtc(),
    fullAt: stamina.fullAt.toUtc(),
    recoverySeconds: stamina.recoveryInterval.inSeconds,
  );

  static List<WidgetItem> _items(GameNote note) => switch (note) {
    GenshinNote() => [
      WidgetItem(
        key: 'realm',
        value: note.realmCurrency.current,
        max: note.realmCurrency.max,
        doneAt: note.realmCurrency.fullAt.toUtc(),
      ),
      _task('commissions', note.commissions),
      _task('weeklyBosses', note.weeklyBossDiscountsLeft),
      WidgetItem(key: 'transformer', doneAt: note.transformerReadyAt?.toUtc()),
      _expeditions('expeditions', note.expeditions, note.fetchedAt),
    ],
    StarRailNote() => [
      _task('reservedPower', note.reservedPower),
      _task('dailyTraining', note.dailyTraining),
      _task('echoOfWar', note.echoOfWarLeft),
      _task('simulatedUniverse', note.simulatedUniverse),
      _expeditions('assignments', note.assignments, note.fetchedAt),
    ],
    ZzzNote() => [
      _task('engagement', note.engagement),
      WidgetItem(
        key: 'scratchCard',
        state: note.scratchCardDone ? 'done' : 'open',
      ),
      WidgetItem(key: 'videoStore', state: note.videoStore.name),
      if (note.bountyCommission case final bounty?)
        _task('bountyCommission', bounty),
      if (note.weeklyProgress case final weekly?)
        _task('weeklyProgress', weekly),
    ],
  };

  static WidgetItem _task(String key, TaskProgress progress) =>
      WidgetItem(key: key, value: progress.done, max: progress.total);

  static WidgetItem _expeditions(
    String key,
    List<Expedition> expeditions,
    DateTime fetchedAt,
  ) => WidgetItem(
    key: key,
    value: expeditions.where((e) => e.isDoneAt(fetchedAt)).length,
    max: expeditions.length,
    doneAt: expeditions.isEmpty
        ? null
        : expeditions
              .map((expedition) => expedition.doneAt)
              .reduce((a, b) => a.isAfter(b) ? a : b)
              .toUtc(),
  );
}
