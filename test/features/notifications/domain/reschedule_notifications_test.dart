import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/dashboard/domain/note_result.dart';
import 'package:hoyo_aio/features/dashboard/domain/notes_repository.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_repositories.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_settings.dart';
import 'package:hoyo_aio/features/notifications/domain/planned_notification.dart';
import 'package:hoyo_aio/features/notifications/domain/reschedule_notifications.dart';

import '../../databook/_support/no_chronicle.dart';
import '../_support/notes.dart';

class _CachedNotes implements NotesRepository {
  _CachedNotes(this.byRole);

  final Map<int, NoteResult> byRole;

  @override
  Future<NoteResult?> cached(SavedRole role) async => byRole[role.id];

  @override
  Future<NoteResult> refresh(SavedRole role) =>
      throw StateError('refresh must not be called');
}

class _RecordingScheduler implements NotificationScheduler {
  final calls = <(List<PlannedNotification>, String?)>[];

  @override
  Future<void> replaceAll(
    List<PlannedNotification> planned, {
    String? localeCode,
  }) async => calls.add((planned, localeCode));
}

void main() {
  test('plans from cached notes only and replaces the schedule', () async {
    final scheduler = _RecordingScheduler();
    final reschedule = RescheduleNotifications(
      _CachedNotes({1: NoteResult(note: genshinNote())}),
      const NoChronicle(),
      scheduler,
      () => fetchedAt,
    );

    final planned = await reschedule(
      roles: [noteRole(1, Game.genshin), noteRole(2, Game.starRail)],
      settings: const NotificationSettings(),
      localeCode: 'id',
    );

    expect(planned.every((p) => p.game == Game.genshin), isTrue);
    expect(planned.map((p) => p.alert), contains(PlannedAlert.staminaFull));
    expect(scheduler.calls.single.$1, planned);
    expect(scheduler.calls.single.$2, 'id');
  });

  test('clears the schedule when notifications are off', () async {
    final scheduler = _RecordingScheduler();
    final reschedule = RescheduleNotifications(
      _CachedNotes({1: NoteResult(note: genshinNote())}),
      const NoChronicle(),
      scheduler,
      () => fetchedAt,
    );

    final planned = await reschedule(
      roles: [noteRole(1, Game.genshin)],
      settings: const NotificationSettings(enabled: false),
    );

    expect(planned, isEmpty);
    expect(scheduler.calls.single.$1, isEmpty);
  });
}
