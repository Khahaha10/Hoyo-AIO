import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_history_repository.dart';
import 'package:hoyo_aio/features/checkin/domain/run_auto_checkin.dart';
import 'package:hoyo_aio/features/dashboard/domain/note_result.dart';
import 'package:hoyo_aio/features/dashboard/domain/notes_repository.dart';
import 'package:hoyo_aio/features/home_widgets/domain/home_widget_repositories.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot_builder.dart';

class UpdateHomeWidgets {
  const UpdateHomeWidgets(
    this._notes,
    this._history,
    this._configs,
    this._bridge,
    this._now,
  );

  final NotesRepository _notes;
  final CheckInHistoryRepository _history;
  final WidgetConfigRepository _configs;
  final HomeWidgetBridge _bridge;
  final DateTime Function() _now;

  Future<WidgetSnapshot> call({
    required List<SavedRole> roles,
    required Set<Game> checkInGames,
    required Map<String, String> labels,
  }) async {
    final now = _now();
    final day = RunAutoCheckIn.dayKey(now);
    final notes = <(SavedRole, NoteResult)>[
      for (final role in roles)
        if (await _notes.cached(role) case final cached?) (role, cached),
    ];
    final snapshot = WidgetSnapshotBuilder.build(
      notes: notes,
      checkInToday: await _history.recordsOn(day),
      day: day,
      checkInTotal: checkInGames.length,
      widgets: await _configs.all(),
      labels: labels,
      now: now,
    );
    await _bridge.publish(snapshot);
    return snapshot;
  }
}
