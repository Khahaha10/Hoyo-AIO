import 'package:freezed_annotation/freezed_annotation.dart';

part 'stamina.freezed.dart';

@freezed
abstract class Stamina with _$Stamina {
  const factory Stamina({
    required int current,
    required int max,
    required DateTime fetchedAt,
    required Duration recoveryInterval,
    DateTime? reportedFullAt,
  }) = _Stamina;

  const Stamina._();

  bool get isFullAtFetch => current >= max;

  DateTime get fullAt {
    if (isFullAtFetch) return fetchedAt;
    final reported = reportedFullAt;
    if (reported != null && reported.isAfter(fetchedAt)) return reported;
    return fetchedAt.add(recoveryInterval * (max - current));
  }

  int currentAt(DateTime now) {
    if (isFullAtFetch || !now.isAfter(fetchedAt)) return current;
    if (recoveryInterval <= Duration.zero) return current;
    final remaining = fullAt.difference(now);
    if (remaining <= Duration.zero) return max;
    final missing = (remaining.inMicroseconds / recoveryInterval.inMicroseconds)
        .ceil();
    return (max - missing).clamp(current, max);
  }

  bool isFullAt(DateTime now) => currentAt(now) >= max;

  DateTime? reachesAt(int value) {
    if (value <= current) return fetchedAt;
    if (value > max) return null;
    return fullAt.subtract(recoveryInterval * (max - value));
  }

  DateTime? nextTickAt(DateTime now) {
    final value = currentAt(now);
    if (value >= max) return null;
    return reachesAt(value + 1);
  }
}
