import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';
import 'package:hoyo_aio/features/dashboard/domain/notes_repository.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_planner.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_repositories.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_settings.dart';
import 'package:hoyo_aio/features/notifications/domain/planned_notification.dart';

class RescheduleNotifications {
  const RescheduleNotifications(this._notes, this._scheduler, this._now);

  final NotesRepository _notes;
  final NotificationScheduler _scheduler;
  final DateTime Function() _now;

  Future<List<PlannedNotification>> call({
    required List<SavedRole> roles,
    required NotificationSettings settings,
    String? localeCode,
  }) async {
    final notes = <(SavedRole, GameNote)>[
      for (final role in roles)
        if (await _notes.cached(role) case final cached?) (role, cached.note),
    ];
    final planned = NotificationPlanner.plan(
      notes: notes,
      settings: settings,
      now: _now(),
    );
    await _scheduler.replaceAll(planned, localeCode: localeCode);
    return planned;
  }
}
