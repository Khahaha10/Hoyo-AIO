import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('clockProvider defaults to the system clock', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final now = container.read(clockProvider)();

    expect(now.difference(DateTime.now()).inSeconds.abs(), lessThan(5));
  });

  testWidgets('clockTick emits now and then on each minute boundary', (
    tester,
  ) async {
    final start = DateTime(2026, 11, 21, 12, 0, 45);
    var elapsed = Duration.zero;
    final container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(() => start.add(elapsed))],
    );
    final ticks = <DateTime>[];
    container.listen(clockTickProvider, (_, next) => next.whenData(ticks.add));
    await tester.pumpWidget(const SizedBox());

    await tester.pump();
    elapsed = const Duration(seconds: 15);
    await tester.pump(const Duration(seconds: 15));
    elapsed = const Duration(seconds: 75);
    await tester.pump(const Duration(minutes: 1));

    expect(ticks, [
      start,
      DateTime(2026, 11, 21, 12, 1),
      DateTime(2026, 11, 21, 12, 2),
    ]);
    container.dispose();
    await tester.pump(const Duration(minutes: 1));
  });
}
