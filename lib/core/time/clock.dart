import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock.g.dart';

typedef Clock = DateTime Function();

@Riverpod(keepAlive: true)
Clock clock(Ref ref) => DateTime.now;

@riverpod
Stream<DateTime> clockTick(Ref ref) async* {
  final now = ref.watch(clockProvider);
  const minute = Duration(minutes: 1);
  yield now();
  while (true) {
    final current = now();
    final sinceMinute = Duration(
      seconds: current.second,
      milliseconds: current.millisecond,
    );
    await Future<void>.delayed(minute - sinceMinute);
    yield now();
  }
}
