import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/dashboard/domain/note_result.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_screen.dart';

import 'dashboard_fakes.dart';
import 'dashboard_harness.dart';

enum DashboardGoldenCase { game, skeleton, error }

void dashboardGoldens(
  String name, {
  DashboardGoldenCase kind = DashboardGoldenCase.game,
  Game game = Game.genshin,
}) {
  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';
    testWidgets('$name ($theme)', (tester) async {
      final repository = GatedNotesRepository();
      for (final g in [Game.genshin, Game.starRail, Game.zzz]) {
        repository.cachedResults[fakeRole(g).id] = NoteResult(
          note: fixtureNote(
            g,
            fetchedAt: kind == DashboardGoldenCase.error
                ? fixedNow.subtract(const Duration(hours: 2))
                : fixedNow,
          ),
        );
      }
      if (kind == DashboardGoldenCase.skeleton) {
        repository
          ..cachedResults.clear()
          ..gate = Completer<NoteResult>();
      }
      await pumpDashboard(
        tester,
        accounts: [
          fakeAccount(
            status: kind == DashboardGoldenCase.error
                ? AccountStatus.expired
                : AccountStatus.valid,
          ),
        ],
        repository: repository,
        dark: dark,
        deepLinkGame: game.name,
        settle: kind != DashboardGoldenCase.skeleton,
      );
      await expectLater(
        find.byType(DashboardScreen),
        matchesGoldenFile('${name}_$theme.png'),
      );
      repository.gate?.complete(NoteResult(note: fixtureNote(game)));
      await tester.pumpAndSettle();
    });
  }
}
