import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/dashboard/domain/expedition.dart';
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_kind.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_planner.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_settings.dart';
import 'package:hoyo_aio/features/notifications/domain/planned_notification.dart';

import '../_support/notes.dart';

const _off = NotificationSettings(
  stamina: false,
  expeditions: false,
  currency: false,
  transformer: false,
);

List<PlannedNotification> _plan(
  List<(SavedRole, GameNote)> notes, {
  NotificationSettings settings = const NotificationSettings(),
  DateTime? now,
}) => NotificationPlanner.plan(
  notes: notes,
  settings: settings,
  now: now ?? fetchedAt,
);

PlannedNotification? _find(List<PlannedNotification> plan, PlannedAlert alert) =>
    plan.where((p) => p.alert == alert).firstOrNull;

void main() {
  final genshin = noteRole(1, Game.genshin);

  test('returns nothing when notifications are off', () {
    final plan = _plan(
      [(genshin, genshinNote())],
      settings: const NotificationSettings(enabled: false, dailyReminder: true),
    );

    expect(plan, isEmpty);
  });

  test('plans every Genshin alert at the computed times', () {
    final plan = _plan([
      (
        genshin,
        genshinNote(
          transformerReadyAt: DateTime(2026, 11, 6, 4),
          expeditions: [
            Expedition(doneAt: DateTime(2026, 11, 5, 12)),
            Expedition(doneAt: DateTime(2026, 11, 5, 18)),
          ],
        ),
      ),
    ]);

    final threshold = _find(plan, PlannedAlert.staminaThreshold)!;
    expect(threshold.at, DateTime(2026, 11, 5, 20, 40));
    expect((threshold.value, threshold.max), (180, 200));
    expect(threshold.kind, NotificationKind.stamina);
    expect(threshold.roleUid, genshin.uid);
    expect(threshold.roleName, genshin.nickname);
    expect(
      threshold.id,
      NotificationPlanner.roleNotificationId(1, PlannedAlert.staminaThreshold),
    );
    final full = _find(plan, PlannedAlert.staminaFull)!;
    expect(full.at, DateTime(2026, 11, 5, 23, 20));
    expect(full.value, 200);
    expect(
      _find(plan, PlannedAlert.expeditionsDone)!.at,
      DateTime(2026, 11, 5, 18),
    );
    final currency = _find(plan, PlannedAlert.currencyFull)!;
    expect(currency.at, DateTime(2026, 11, 8, 8));
    expect(currency.max, isNull);
    expect(currency.kind, NotificationKind.currency);
    final transformer = _find(plan, PlannedAlert.transformerReady)!;
    expect(transformer.at, DateTime(2026, 11, 6, 4));
    expect(transformer.kind, NotificationKind.transformer);
    expect(
      _find(plan, PlannedAlert.expeditionsDone)!.kind,
      NotificationKind.expeditions,
    );
  });

  test('Star Rail assignments plan expeditionsDone, ZZZ has none', () {
    final plan = _plan([
      (
        noteRole(2, Game.starRail),
        starRailNote(
          assignments: [Expedition(doneAt: DateTime(2026, 11, 5, 15))],
        ),
      ),
      (noteRole(3, Game.zzz), zzzNote()),
    ]);

    final done = plan.where((p) => p.alert == PlannedAlert.expeditionsDone);
    expect(done.single.game, Game.starRail);
    expect(plan.where((p) => p.game == Game.zzz).map((p) => p.alert), [
      PlannedAlert.staminaThreshold,
      PlannedAlert.staminaFull,
    ]);
  });

  test('respects each alert toggle', () {
    final plan = _plan(
      [
        (
          genshin,
          genshinNote(
            transformerReadyAt: DateTime(2026, 11, 6),
            expeditions: [Expedition(doneAt: DateTime(2026, 11, 5, 12))],
          ),
        ),
      ],
      settings: _off,
    );

    expect(plan, isEmpty);
  });

  test('skips realm currency without a cap', () {
    final plan = _plan([
      (genshin, genshinNote(realmCurrency: stamina(current: 0, max: 0))),
    ], settings: _off.copyWith(currency: true));

    expect(plan, isEmpty);
  });

  test('no threshold alert at 100 percent', () {
    final plan = _plan(
      [(genshin, genshinNote())],
      settings: _off.copyWith(stamina: true, staminaThresholdPercent: 100),
    );

    expect(plan.map((p) => p.alert), [PlannedAlert.staminaFull]);
  });

  test('skips times that are not after now', () {
    final plan = _plan(
      [
        (genshin, genshinNote(resin: stamina(current: 200))),
        (
          noteRole(2, Game.starRail),
          starRailNote(power: stamina(current: 230, max: 240)),
        ),
      ],
      settings: _off.copyWith(stamina: true),
    );

    expect(plan.map((p) => (p.game, p.alert)), [
      (Game.starRail, PlannedAlert.staminaFull),
    ]);
  });

  test('skips everything already past for a late now', () {
    final plan = _plan(
      [(genshin, genshinNote())],
      now: DateTime(2026, 12),
    );

    expect(plan, isEmpty);
  });

  test('gives every role and alert a unique id', () {
    final plan = _plan(
      [
        for (var id = 1; id <= 3; id++)
          (
            noteRole(id, Game.genshin),
            genshinNote(
              transformerReadyAt: DateTime(2026, 11, 6),
              expeditions: [Expedition(doneAt: DateTime(2026, 11, 5, 12))],
            ),
          ),
      ],
      settings: const NotificationSettings(dailyReminder: true),
    );

    expect(plan, hasLength(16));
    expect(plan.map((p) => p.id).toSet(), hasLength(plan.length));
  });

  group('daily reminder', () {
    const settings = NotificationSettings(
      stamina: false,
      expeditions: false,
      currency: false,
      transformer: false,
      dailyReminder: true,
      dailyReminderMinutes: 21 * 60,
    );

    test('is today when the time is ahead', () {
      final plan = _plan(const [], settings: settings);

      expect(plan.single.id, NotificationPlanner.dailyReminderId);
      expect(plan.single.at, DateTime(2026, 11, 5, 21));
      expect(plan.single.kind, NotificationKind.dailyReminder);
      expect(plan.single.game, isNull);
    });

    test('is tomorrow when the time has passed', () {
      final plan = _plan(
        const [],
        settings: settings,
        now: DateTime(2026, 11, 30, 21),
      );

      expect(plan.single.at, DateTime(2026, 12, 1, 21));
    });

    test('is dropped inside quiet hours', () {
      final plan = _plan(
        const [],
        settings: settings.copyWith(
          quietHours: true,
          quietStartMinutes: 20 * 60,
          quietEndMinutes: 22 * 60,
        ),
      );

      expect(plan, isEmpty);
    });
  });

  group('quiet hours', () {
    PlannedNotification? transformerAt(
      DateTime at,
      NotificationSettings settings,
    ) => _plan(
      [(genshin, genshinNote(transformerReadyAt: at))],
      settings: settings.copyWith(transformer: true),
      now: DateTime(2026, 11, 5),
    ).singleOrNull;

    final cases = <(String, int, int, DateTime, DateTime)>[
      (
        'same-day window shifts to its end',
        12 * 60,
        14 * 60,
        DateTime(2026, 11, 5, 13),
        DateTime(2026, 11, 5, 14),
      ),
      (
        'same-day window keeps times outside it',
        12 * 60,
        14 * 60,
        DateTime(2026, 11, 5, 14),
        DateTime(2026, 11, 5, 14),
      ),
      (
        'overnight window shifts late evening to next morning',
        23 * 60,
        7 * 60,
        DateTime(2026, 11, 5, 23, 30),
        DateTime(2026, 11, 6, 7),
      ),
      (
        'overnight window shifts early morning to the same morning',
        23 * 60,
        7 * 60,
        DateTime(2026, 11, 6, 1),
        DateTime(2026, 11, 6, 7),
      ),
      (
        'overnight window keeps the afternoon',
        23 * 60,
        7 * 60,
        DateTime(2026, 11, 5, 15),
        DateTime(2026, 11, 5, 15),
      ),
      (
        'overnight window crosses the month end',
        22 * 60,
        6 * 60,
        DateTime(2026, 11, 30, 22),
        DateTime(2026, 12, 1, 6),
      ),
      (
        'equal start and end disable the window',
        8 * 60,
        8 * 60,
        DateTime(2026, 11, 5, 9),
        DateTime(2026, 11, 5, 9),
      ),
    ];
    for (final (name, start, end, at, expected) in cases) {
      test(name, () {
        final item = transformerAt(
          at,
          _off.copyWith(
            quietHours: true,
            quietStartMinutes: start,
            quietEndMinutes: end,
          ),
        );

        expect(item?.at, expected);
      });
    }

    test('is ignored when switched off', () {
      final item = transformerAt(
        DateTime(2026, 11, 5, 23, 30),
        _off.copyWith(quietStartMinutes: 23 * 60, quietEndMinutes: 7 * 60),
      );

      expect(item?.at, DateTime(2026, 11, 5, 23, 30));
    });

    test('reads UTC times in local time', () {
      final local = DateTime(2026, 11, 5, 23, 30);
      final item = transformerAt(
        local.toUtc(),
        _off.copyWith(
          quietHours: true,
          quietStartMinutes: 23 * 60,
          quietEndMinutes: 7 * 60,
        ),
      );

      expect(item?.at.isAtSameMomentAs(DateTime(2026, 11, 6, 7)), isTrue);
    });

    test('drops a threshold alert shifted onto the full alert', () {
      final plan = _plan(
        [(genshin, genshinNote())],
        settings: _off.copyWith(
          stamina: true,
          quietHours: true,
          quietStartMinutes: 20 * 60,
          quietEndMinutes: 7 * 60,
        ),
      );

      expect(plan.single.alert, PlannedAlert.staminaFull);
      expect(plan.single.at, DateTime(2026, 11, 6, 7));
    });
  });
}
