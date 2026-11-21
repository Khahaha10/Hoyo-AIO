import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_record.dart';

import '../_support/tracker_support.dart';

List<GachaRecord> ranks(
  List<int> values, {
  Map<int, String> names = const {},
}) => [
  for (final (index, rank) in values.indexed)
    gachaRecord(index + 1, rank: rank, name: names[index + 1] ?? 'Item'),
];

void main() {
  group('BannerPity.of pity counters', () {
    final cases = <({String name, List<int> ranks, int pity5, int pity4})>[
      (name: 'empty banner', ranks: [], pity5: 0, pity4: 0),
      (name: 'only 3 stars', ranks: [3, 3, 3], pity5: 3, pity4: 3),
      (
        name: '4 star resets 4 pity',
        ranks: [3, 3, 4, 3, 3],
        pity5: 5,
        pity4: 2,
      ),
      (name: '5 star resets both', ranks: [3, 4, 5, 3], pity5: 1, pity4: 1),
      (name: 'last pull is 5 star', ranks: [3, 3, 5], pity5: 0, pity4: 0),
      (name: 'last pull is 4 star', ranks: [3, 3, 4], pity5: 3, pity4: 0),
    ];
    for (final c in cases) {
      test(c.name, () {
        final pity = BannerPity.of('301', ranks(c.ranks));

        expect(pity.total, c.ranks.length);
        expect(pity.pity5, c.pity5);
        expect(pity.pity4, c.pity4);
      });
    }
  });

  test('sorts by record id before counting', () {
    final pity = BannerPity.of('301', [
      gachaRecord(3),
      gachaRecord(1, rank: 5),
      gachaRecord(2),
    ]);

    expect(pity.pity5, 2);
    expect(pity.fiveStars.single.pulls, 1);
  });

  test('lists 5 stars newest first with pull counts and average', () {
    final records = ranks(
      [for (var i = 0; i < 9; i++) 3, 5, 3, 3, 5, 3],
      names: {10: 'First', 13: 'Second'},
    );

    final pity = BannerPity.of('301', records);

    expect(pity.fiveStars.map((pull) => pull.record.name), ['Second', 'First']);
    expect(pity.fiveStars.map((pull) => pull.pulls), [3, 10]);
    expect(pity.averageFiveStar, 6.5);
    expect(pity.rowPity[10], 10);
    expect(pity.rowPity[13], 3);
    expect(pity.fiveStarFor(13)?.record.name, 'Second');
    expect(pity.fiveStarFor(1), isNull);
  });

  test('records 4 star row pity since the last 4 or 5 star', () {
    final pity = BannerPity.of('301', ranks([3, 4, 3, 3, 4, 5, 4]));

    expect(pity.rowPity, {2: 2, 5: 3, 6: 6, 7: 1});
  });

  test('average is null without any 5 star', () {
    expect(BannerPity.of('301', ranks([3, 4])).averageFiveStar, isNull);
  });

  group('50/50 with a standard pool', () {
    const pool = {'Diluc'};

    final cases =
        <
          ({
            String name,
            List<String> fiveStars,
            List<FiftyFifty> results,
            bool guaranteed,
            int won,
            int total,
          })
        >[
          (
            name: 'limited first pull wins',
            fiveStars: ['Limited'],
            results: [FiftyFifty.won],
            guaranteed: false,
            won: 1,
            total: 1,
          ),
          (
            name: 'standard pull loses and guarantees the next',
            fiveStars: ['Diluc'],
            results: [FiftyFifty.lost],
            guaranteed: true,
            won: 0,
            total: 1,
          ),
          (
            name: 'pull after a loss is guaranteed, then 50/50 again',
            fiveStars: ['Diluc', 'Limited', 'Limited'],
            results: [FiftyFifty.lost, FiftyFifty.guaranteed, FiftyFifty.won],
            guaranteed: false,
            won: 1,
            total: 2,
          ),
          (
            name:
                'standard character on a guarantee still counts as guaranteed',
            fiveStars: ['Diluc', 'Diluc'],
            results: [FiftyFifty.lost, FiftyFifty.guaranteed],
            guaranteed: false,
            won: 0,
            total: 1,
          ),
        ];
    for (final c in cases) {
      test(c.name, () {
        final records = [
          for (final (index, name) in c.fiveStars.indexed)
            gachaRecord(index + 1, rank: 5, name: name),
        ];

        final pity = BannerPity.of('301', records, standardPool: pool);

        expect(
          pity.fiveStars.reversed.map((pull) => pull.fiftyFifty),
          c.results,
        );
        expect(pity.guaranteed, c.guaranteed);
        expect(pity.fiftyFiftyWon, c.won);
        expect(pity.fiftyFiftyTotal, c.total);
      });
    }
  });

  test('without a standard pool there is no 50/50 result', () {
    final pity = BannerPity.of('302', [gachaRecord(1, rank: 5, name: 'Diluc')]);

    expect(pity.fiveStars.single.fiftyFifty, isNull);
    expect(pity.guaranteed, isFalse);
    expect(pity.fiftyFiftyTotal, 0);
  });
}
