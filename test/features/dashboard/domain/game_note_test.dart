import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/dashboard/domain/expedition.dart';
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';
import 'package:hoyo_aio/features/dashboard/domain/task_progress.dart';

import '../_support/dashboard_fakes.dart';

void main() {
  group('TaskProgress.isComplete', () {
    final cases = <(int, int, bool)>[
      (0, 0, false),
      (3, 4, false),
      (4, 4, true),
      (5, 4, true),
    ];
    for (final (done, total, expected) in cases) {
      test('$done/$total is ${expected ? '' : 'not '}complete', () {
        expect(TaskProgress(done: done, total: total).isComplete, expected);
      });
    }
  });

  group('Expedition', () {
    final doneAt = DateTime.utc(2026, 11, 21, 12);

    test('is not done before doneAt and reports remaining time', () {
      final now = doneAt.subtract(const Duration(minutes: 30));
      final value = Expedition(doneAt: doneAt);
      expect(value.isDoneAt(now), isFalse);
      expect(value.remainingAt(now), const Duration(minutes: 30));
    });

    test('is done at and after doneAt with zero remaining', () {
      final value = Expedition(doneAt: doneAt, name: 'Run');
      expect(value.isDoneAt(doneAt), isTrue);
      expect(
        value.remainingAt(doneAt.add(const Duration(hours: 1))),
        Duration.zero,
      );
    });
  });

  group('GameNote', () {
    for (final game in [Game.genshin, Game.starRail, Game.zzz]) {
      test('${game.name} note exposes its game and stamina', () {
        final note = fixtureNote(game);
        expect(note.game, game);
        final stamina = switch (note) {
          GenshinNote(:final resin) => resin,
          StarRailNote(:final trailblazePower) => trailblazePower,
          ZzzNote(:final battery) => battery,
        };
        expect(note.stamina, stamina);
      });
    }
  });
}
