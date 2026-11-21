import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/features/dashboard/domain/stamina.dart';

void main() {
  final t0 = DateTime.utc(2026, 11, 21, 10);
  const tick = Duration(minutes: 8);

  Stamina resin({
    int current = 142,
    int max = 200,
    Duration interval = tick,
    DateTime? reportedFullAt,
  }) => Stamina(
    current: current,
    max: max,
    fetchedAt: t0,
    recoveryInterval: interval,
    reportedFullAt: reportedFullAt,
  );

  group('currentAt', () {
    final cases = <(String, Stamina, Duration, int)>[
      ('returns current at fetch time', resin(), Duration.zero, 142),
      (
        'stays put one second before a tick',
        resin(),
        tick - const Duration(seconds: 1),
        142,
      ),
      ('ticks up exactly at the tick', resin(), tick, 143),
      ('counts several ticks', resin(), tick * 10, 152),
      ('caps at max exactly when full', resin(), tick * 58, 200),
      ('never overflows past max', resin(), const Duration(days: 3), 200),
      (
        'keeps the fetched value when already full',
        resin(current: 200),
        const Duration(hours: 5),
        200,
      ),
      (
        'keeps an over-cap value',
        resin(current: 210),
        const Duration(hours: 1),
        210,
      ),
      (
        'ignores a clock behind fetch time',
        resin(),
        -const Duration(hours: 1),
        142,
      ),
      (
        'does not grow without a recovery interval',
        resin(interval: Duration.zero),
        const Duration(hours: 9),
        142,
      ),
    ];
    for (final (name, stamina, offset, expected) in cases) {
      test(name, () {
        expect(stamina.currentAt(t0.add(offset)), expected);
      });
    }
  });

  group('fullAt', () {
    test('equals fetch time when already full', () {
      expect(resin(current: 200).fullAt, t0);
    });

    test('is computed from missing points times interval', () {
      expect(resin().fullAt, t0.add(tick * 58));
    });

    test('prefers the reported full time when it is after fetch', () {
      final reported = t0.add(const Duration(hours: 3));
      expect(resin(reportedFullAt: reported).fullAt, reported);
    });

    test('ignores a reported full time in the past', () {
      final reported = t0.subtract(const Duration(minutes: 1));
      expect(resin(reportedFullAt: reported).fullAt, t0.add(tick * 58));
    });

    test('uses the reported full time for local extrapolation', () {
      final stamina = resin(reportedFullAt: t0.add(tick * 50));
      expect(stamina.currentAt(t0.add(tick)), 151);
    });
  });

  group('threshold and ticks', () {
    final cases = <(String, int, DateTime?)>[
      ('value below current is already reached', 100, t0),
      ('current value is already reached', 142, t0),
      ('threshold 180 is 20 ticks before full', 180, t0.add(tick * 38)),
      ('max equals full time', 200, t0.add(tick * 58)),
      ('value above max is never reached', 201, null),
    ];
    for (final (name, value, expected) in cases) {
      test(name, () {
        expect(resin().reachesAt(value), expected);
      });
    }

    test('nextTickAt returns the next point time', () {
      expect(resin().nextTickAt(t0), t0.add(tick));
      expect(
        resin().nextTickAt(t0.add(tick + const Duration(minutes: 1))),
        t0.add(tick * 2),
      );
    });

    test('nextTickAt is null once full', () {
      expect(resin().nextTickAt(t0.add(const Duration(days: 1))), isNull);
    });

    test('isFullAt flips when max is reached', () {
      expect(resin().isFullAt(t0), isFalse);
      expect(resin().isFullAt(t0.add(tick * 58)), isTrue);
      expect(resin(current: 200).isFullAtFetch, isTrue);
    });
  });
}
