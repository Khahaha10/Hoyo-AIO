import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/notifications/data/notification_scheduler_impl.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_kind.dart';
import 'package:hoyo_aio/features/notifications/domain/planned_notification.dart';
import 'package:material_ui/material_ui.dart';

import '../_support/recording_notification_service.dart';

final _at = DateTime(2026, 11, 5, 20);
final _en = lookupAppLocalizations(const Locale('en'));

PlannedNotification _item(
  PlannedAlert alert, {
  Game? game = Game.genshin,
  int id = 1,
}) => PlannedNotification(
  id: id,
  alert: alert,
  at: _at,
  game: game,
  roleUid: game == null ? null : '800000001',
  roleName: game == null ? null : 'Tester',
  value: 180,
  max: 200,
);

void main() {
  test('replaceAll hands every planned item to the service once', () async {
    final service = RecordingNotificationService();
    final scheduler = NotificationSchedulerImpl(service);

    await scheduler.replaceAll([
      _item(PlannedAlert.staminaThreshold, id: 1),
      _item(PlannedAlert.dailyReminder, game: null, id: 2),
    ], localeCode: 'en');

    final messages = service.scheduled.single;
    expect(messages.map((m) => m.id), [1, 2]);
    expect(messages.first.kind, NotificationKind.stamina);
    expect(messages.first.at, _at);
    expect(messages.first.title, _en.notifyStaminaThreshold(_en.genshinResin, 180, 200));
    expect(messages.first.body, _en.notifyRoleLine('Tester', _en.gameGenshin));
    expect(
      messages.first.payload,
      'hoyoaio://dashboard?game=genshin&role=800000001',
    );
    expect(messages.last.title, _en.notifyDailyReminder);
    expect(messages.last.body, _en.notifyDailyReminderBody);
    expect(messages.last.payload, isNull);
  });

  test('replaceAll with an empty plan clears the schedule', () async {
    final service = RecordingNotificationService();

    await NotificationSchedulerImpl(service).replaceAll(const []);

    expect(service.scheduled.single, isEmpty);
  });

  test('titles name the stamina of each game', () async {
    final service = RecordingNotificationService();
    final games = [Game.genshin, Game.starRail, Game.zzz, Game.hi3];

    await NotificationSchedulerImpl(service).replaceAll([
      for (final (index, game) in games.indexed)
        _item(PlannedAlert.staminaFull, game: game, id: index),
    ], localeCode: 'en');

    expect(service.scheduled.single.map((m) => m.title), [
      _en.notifyStaminaFull(_en.genshinResin),
      _en.notifyStaminaFull(_en.starRailTrailblazePower),
      _en.notifyStaminaFull(_en.zzzBattery),
      _en.notifyStaminaFull(''),
    ]);
  });

  test('titles cover every alert kind', () async {
    final service = RecordingNotificationService();

    await NotificationSchedulerImpl(service).replaceAll([
      _item(PlannedAlert.expeditionsDone, id: 1),
      _item(PlannedAlert.expeditionsDone, game: Game.starRail, id: 2),
      _item(PlannedAlert.currencyFull, id: 3),
      _item(PlannedAlert.transformerReady, id: 4),
    ], localeCode: 'en');

    expect(service.scheduled.single.map((m) => m.title), [
      _en.notifyExpeditionsDone,
      _en.notifyAssignmentsDone,
      _en.notifyCurrencyFull,
      _en.notifyTransformerReady,
    ]);
  });

  test('uses the requested locale and falls back to English', () {
    expect(NotificationSchedulerImpl.resolveL10n('id').localeName, 'id');
    expect(NotificationSchedulerImpl.resolveL10n('xx').localeName, 'en');
  });
}
