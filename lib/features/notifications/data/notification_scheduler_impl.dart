import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/game_labels.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/l10n/resolve_l10n.dart' as l10n_resolver;
import 'package:hoyo_aio/features/notifications/data/notification_service.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_repositories.dart';
import 'package:hoyo_aio/features/notifications/domain/planned_notification.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_scheduler_impl.g.dart';

class NotificationSchedulerImpl implements NotificationScheduler {
  const NotificationSchedulerImpl(this._service);

  final NotificationService _service;

  @override
  Future<void> replaceAll(
    List<PlannedNotification> planned, {
    String? localeCode,
  }) {
    final l10n = resolveL10n(localeCode);
    return _service.replaceScheduled([
      for (final item in planned)
        ScheduledMessage(
          id: item.id,
          kind: item.kind,
          at: item.at,
          title: _title(item, l10n),
          body: _body(item, l10n),
          payload: _payload(item),
        ),
    ]);
  }

  static AppLocalizations resolveL10n(String? localeCode) =>
      l10n_resolver.resolveL10n(localeCode);

  static String _staminaName(Game? game, AppLocalizations l10n) =>
      switch (game) {
        Game.genshin => l10n.genshinResin,
        Game.starRail => l10n.starRailTrailblazePower,
        Game.zzz => l10n.zzzBattery,
        Game.hi3 || null => '',
      };

  static String _title(PlannedNotification item, AppLocalizations l10n) =>
      switch (item.alert) {
        PlannedAlert.staminaThreshold => l10n.notifyStaminaThreshold(
          _staminaName(item.game, l10n),
          item.value ?? 0,
          item.max ?? 0,
        ),
        PlannedAlert.staminaFull => l10n.notifyStaminaFull(
          _staminaName(item.game, l10n),
        ),
        PlannedAlert.expeditionsDone =>
          item.game == Game.starRail
              ? l10n.notifyAssignmentsDone
              : l10n.notifyExpeditionsDone,
        PlannedAlert.currencyFull => l10n.notifyCurrencyFull,
        PlannedAlert.transformerReady => l10n.notifyTransformerReady,
        PlannedAlert.dailyReminder => l10n.notifyDailyReminder,
      };

  static String _body(PlannedNotification item, AppLocalizations l10n) {
    final game = item.game;
    if (game == null) return l10n.notifyDailyReminderBody;
    return l10n.notifyRoleLine(item.roleName ?? '', l10n.gameName(game));
  }

  static String? _payload(PlannedNotification item) {
    final game = item.game;
    if (game == null) return null;
    return Uri(
      scheme: 'hoyoaio',
      host: 'dashboard',
      queryParameters: {'game': game.name, 'role': ?item.roleUid},
    ).toString();
  }
}

@Riverpod(keepAlive: true)
NotificationScheduler notificationScheduler(Ref ref) =>
    NotificationSchedulerImpl(ref.watch(notificationServiceProvider));
