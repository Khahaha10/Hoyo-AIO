import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/dashboard/domain/expedition.dart';
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_settings.dart';
import 'package:hoyo_aio/features/notifications/domain/planned_notification.dart';

abstract final class NotificationPlanner {
  static const dailyReminderId = 1;
  static const _roleIdBase = 1000;
  static const _slotsPerRole = 10;
  static const _percent = 100;
  static const _endgameIdBase = 200000;
  static const _endgameSlotsPerRole = 100;
  static const endgameLead = Duration(hours: 24);

  static int endgameNotificationId(int roleId, EndgameMode mode) =>
      _endgameIdBase + roleId * _endgameSlotsPerRole + mode.index;

  static int roleNotificationId(int roleId, PlannedAlert alert) =>
      _roleIdBase + roleId * _slotsPerRole + alert.index;

  static List<PlannedNotification> plan({
    required List<(SavedRole, GameNote)> notes,
    required NotificationSettings settings,
    required DateTime now,
    List<(SavedRole, List<EndgameSummary>)> endgame = const [],
  }) {
    if (!settings.enabled) return const [];
    final planned = [
      for (final (role, note) in notes) ..._forRole(role, note, settings),
      if (settings.endgameReset)
        for (final (role, summaries) in endgame)
          for (final summary in summaries) ?_endgameReset(role, summary),
      if (settings.dailyReminder)
        PlannedNotification(
          id: dailyReminderId,
          alert: PlannedAlert.dailyReminder,
          at: _nextAt(settings.dailyReminderMinutes, now),
        ),
    ];
    final result = <PlannedNotification>[];
    for (final item in planned) {
      final adjusted = _applyQuietHours(item, settings);
      if (adjusted == null || !adjusted.at.isAfter(now)) continue;
      result.add(adjusted);
    }
    return _dropShadowedThresholds(result);
  }

  static List<PlannedNotification> _forRole(
    SavedRole role,
    GameNote note,
    NotificationSettings settings,
  ) {
    PlannedNotification item(PlannedAlert alert, DateTime at, {int? value}) =>
        PlannedNotification(
          id: roleNotificationId(role.id, alert),
          alert: alert,
          at: at,
          game: role.game,
          roleUid: role.uid,
          roleName: role.nickname,
          value: value,
          max: alert == PlannedAlert.currencyFull ? null : note.stamina.max,
        );
    final stamina = note.stamina;
    final threshold =
        (stamina.max * settings.staminaThresholdPercent / _percent).ceil();
    final thresholdAt = threshold < stamina.max
        ? stamina.reachesAt(threshold)
        : null;
    final expeditions = switch (note) {
      GenshinNote(:final expeditions) => expeditions,
      StarRailNote(:final assignments) => assignments,
      ZzzNote() => const <Expedition>[],
    };
    return [
      if (settings.stamina && thresholdAt != null)
        item(PlannedAlert.staminaThreshold, thresholdAt, value: threshold),
      if (settings.stamina)
        item(PlannedAlert.staminaFull, stamina.fullAt, value: stamina.max),
      if (settings.expeditions && expeditions.isNotEmpty)
        item(
          PlannedAlert.expeditionsDone,
          expeditions
              .map((expedition) => expedition.doneAt)
              .reduce((a, b) => a.isAfter(b) ? a : b),
        ),
      if (note case GenshinNote(:final realmCurrency)
          when settings.currency && realmCurrency.max > 0)
        item(PlannedAlert.currencyFull, realmCurrency.fullAt),
      if (note case GenshinNote(:final transformerReadyAt?)
          when settings.transformer)
        item(PlannedAlert.transformerReady, transformerReadyAt),
    ];
  }

  static PlannedNotification? _endgameReset(
    SavedRole role,
    EndgameSummary summary,
  ) {
    final end = summary.endsAt;
    final max = summary.maxStars;
    final stars = summary.stars ?? 0;
    if (end == null || max == null || stars >= max) return null;
    return PlannedNotification(
      id: endgameNotificationId(role.id, summary.mode),
      alert: PlannedAlert.endgameReset,
      at: end.subtract(endgameLead),
      game: role.game,
      roleUid: role.uid,
      roleName: role.nickname,
      value: stars,
      max: max,
      mode: summary.mode.name,
    );
  }

  static PlannedNotification? _applyQuietHours(
    PlannedNotification item,
    NotificationSettings settings,
  ) {
    if (!settings.quietHours) return item;
    final start = settings.quietStartMinutes;
    final end = settings.quietEndMinutes;
    if (start == end) return item;
    final local = item.at.toLocal();
    final minute = local.hour * Duration.minutesPerHour + local.minute;
    final inQuiet = start < end
        ? minute >= start && minute < end
        : minute >= start || minute < end;
    if (!inQuiet) return item;
    if (item.alert == PlannedAlert.dailyReminder) return null;
    return item.copyWith(at: _nextAt(end, local));
  }

  static List<PlannedNotification> _dropShadowedThresholds(
    List<PlannedNotification> items,
  ) {
    final fullAt = {
      for (final item in items)
        if (item.alert == PlannedAlert.staminaFull) item.roleUid: item.at,
    };
    return [
      for (final item in items)
        if (item.alert != PlannedAlert.staminaThreshold ||
            fullAt[item.roleUid] != item.at)
          item,
    ];
  }

  static DateTime _nextAt(int minutesOfDay, DateTime after) {
    final local = after.toLocal();
    final today = DateTime(
      local.year,
      local.month,
      local.day,
      minutesOfDay ~/ Duration.minutesPerHour,
      minutesOfDay % Duration.minutesPerHour,
    );
    return today.isAfter(local)
        ? today
        : DateTime(
            today.year,
            today.month,
            today.day + 1,
            today.hour,
            today.minute,
          );
  }
}
