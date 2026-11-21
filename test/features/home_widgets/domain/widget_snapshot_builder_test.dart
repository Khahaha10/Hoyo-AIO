import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';
import 'package:hoyo_aio/features/dashboard/domain/note_result.dart';
import 'package:hoyo_aio/features/dashboard/domain/stamina.dart';
import 'package:hoyo_aio/features/dashboard/domain/task_progress.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot_builder.dart';

import '../_support/widget_fixtures.dart';

WidgetSnapshot _build({
  List<CheckInRecordLike> checkIn = const [],
  int total = 3,
}) => WidgetSnapshotBuilder.build(
  notes: allNotes,
  checkInToday: [for (final (game, result) in checkIn) record(game, result)],
  day: '2026-11-21',
  checkInTotal: total,
  widgets: [config()],
  labels: testLabels,
  now: fetchedAt.add(const Duration(minutes: 5)),
);

typedef CheckInRecordLike = (Game, CheckInResult);

WidgetItem _item(WidgetRoleSnapshot role, String key) =>
    role.items.singleWhere((i) => i.key == key);

void main() {
  group('WidgetSnapshotBuilder.build', () {
    test('writes version, labels, widget configs and UTC generatedAt', () {
      final snapshot = _build();

      expect(snapshot.version, WidgetSnapshotBuilder.version);
      expect(snapshot.labels, testLabels);
      expect(snapshot.widgets, [config()]);
      expect(snapshot.generatedAt.isUtc, isTrue);
      expect(
        snapshot.generatedAt,
        fetchedAt.add(const Duration(minutes: 5)).toUtc(),
      );
    });

    test('maps one role per note with identity and stale flag', () {
      final roles = _build().roles;

      expect(roles.map((r) => r.roleId), [1, 2, 3]);
      expect(roles.map((r) => r.game), [Game.genshin, Game.starRail, Game.zzz]);
      expect(roles.first.uid, '800000001');
      expect(roles.first.name, 'Tester1');
      expect(roles.map((r) => r.stale), [false, true, false]);
      expect(roles.every((r) => r.fetchedAt.isUtc), isTrue);
    });

    test('stores stamina as absolute UTC times with recovery seconds', () {
      final roles = _build().roles;
      final resin = roles[0].stamina;

      expect(resin.key, 'resin');
      expect(resin.current, 100);
      expect(resin.max, 200);
      expect(resin.recoverySeconds, 480);
      expect(resin.fetchedAt.isUtc, isTrue);
      expect(resin.fullAt.isUtc, isTrue);
      expect(resin.fullAt, fetchedAt.add(const Duration(minutes: 800)).toUtc());
      expect(roles[1].stamina.key, 'trailblazePower');
      expect(roles[1].stamina.fullAt, fetchedAt.toUtc());
      expect(roles[2].stamina.key, 'battery');
    });

    test(
      'builds Genshin items with realm, tasks, transformer, expeditions',
      () {
        final genshin = _build().roles[0];

        expect(genshin.items.map((i) => i.key), [
          'realm',
          'commissions',
          'weeklyBosses',
          'transformer',
          'expeditions',
        ]);
        final realm = _item(genshin, 'realm');
        expect((realm.value, realm.max), (1200, 2400));
        expect(realm.doneAt?.isUtc, isTrue);
        expect(_item(genshin, 'commissions').value, 2);
        expect(_item(genshin, 'weeklyBosses').max, 3);
        expect(
          _item(genshin, 'transformer').doneAt,
          fetchedAt.add(const Duration(hours: 5)).toUtc(),
        );
        final expeditions = _item(genshin, 'expeditions');
        expect((expeditions.value, expeditions.max), (1, 3));
        expect(
          expeditions.doneAt,
          fetchedAt.add(const Duration(hours: 6)).toUtc(),
        );
      },
    );

    test('builds Star Rail items with empty assignments and no doneAt', () {
      final starRail = _build().roles[1];

      expect(starRail.items.map((i) => i.key), [
        'reservedPower',
        'dailyTraining',
        'echoOfWar',
        'simulatedUniverse',
        'assignments',
      ]);
      final assignments = _item(starRail, 'assignments');
      expect((assignments.value, assignments.max), (0, 0));
      expect(assignments.doneAt, isNull);
    });

    test('builds ZZZ items with states and optional tasks', () {
      final zzz = _build().roles[2];

      expect(zzz.items.map((i) => i.key), [
        'engagement',
        'scratchCard',
        'videoStore',
        'bountyCommission',
      ]);
      expect(_item(zzz, 'scratchCard').state, 'done');
      expect(_item(zzz, 'videoStore').state, 'revenueReady');
    });

    test('marks an open scratch card and includes weekly progress', () {
      final note = GameNote.zzz(
        fetchedAt: fetchedAt,
        battery: Stamina(
          current: 1,
          max: 240,
          fetchedAt: fetchedAt,
          recoveryInterval: const Duration(minutes: 6),
        ),
        engagement: const TaskProgress(done: 0, total: 400),
        scratchCardDone: false,
        videoStore: VideoStoreState.closed,
        bountyCommission: null,
        weeklyProgress: const TaskProgress(done: 2, total: 7),
      );

      final zzz = WidgetSnapshotBuilder.build(
        notes: [(zzzRole, NoteResult(note: note))],
        checkInToday: const [],
        day: '2026-11-21',
        checkInTotal: 0,
        widgets: const [],
        labels: const {},
        now: fetchedAt,
      ).roles.single;

      expect(zzz.items.map((i) => i.key), [
        'engagement',
        'scratchCard',
        'videoStore',
        'weeklyProgress',
      ]);
      expect(_item(zzz, 'scratchCard').state, 'open');
    });

    test('counts each successful check-in game once for today', () {
      final snapshot = _build(
        checkIn: const [
          (Game.genshin, CheckInResult.claimed),
          (Game.genshin, CheckInResult.alreadyClaimed),
          (Game.starRail, CheckInResult.alreadyClaimed),
          (Game.zzz, CheckInResult.captcha),
        ],
      );

      expect(snapshot.checkIn.day, '2026-11-21');
      expect(snapshot.checkIn.done, 2);
      expect(snapshot.checkIn.total, 3);
    });
  });
}
