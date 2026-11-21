@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/tracker/data/gacha_repository_impl.dart';
import 'package:hoyo_aio/features/tracker/presentation/tracker_screen.dart';

import '../features/tracker/_support/tracker_support.dart';

void main() {
  final records = [
    for (var id = 1; id <= 70; id++)
      gachaRecord(
        id,
        rank: switch (id) {
          12 || 60 || 64 => 5,
          5 || 20 || 30 || 40 || 50 => 4,
          _ => 3,
        },
        name: switch (id) {
          12 => 'Diluc',
          60 => 'Furina',
          64 => 'Neuvillette',
          _ => 'Item $id',
        },
      ),
  ];

  for (final dark in [false, true]) {
    final name = dark ? 'dark' : 'light';
    testWidgets('tracker screen $name', (tester) async {
      useTallSurface(tester);
      await pumpScreen(
        tester,
        const TrackerScreen(game: Game.genshin),
        dark: dark,
        overrides: [
          gachaRepositoryProvider.overrideWithValue(
            FakeGachaRepository(records: {Game.genshin: records}),
          ),
          ...clockOverrides(),
        ],
      );

      await expectLater(
        find.byType(TrackerScreen),
        matchesGoldenFile('tracker_screen_$name.png'),
      );
    });
  }
}
