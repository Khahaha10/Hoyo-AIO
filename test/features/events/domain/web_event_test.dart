import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/features/events/domain/web_event.dart';

import '../../codes/_support/community_fakes.dart';
import '../../tracker/_support/tracker_support.dart';

void main() {
  const minute = Duration(minutes: 1);
  final cases = <(String, Duration, Duration, EventPhase)>[
    ('started and not ended', -minute, minute, EventPhase.running),
    ('starts exactly now', Duration.zero, minute, EventPhase.running),
    ('starts later', minute, minute * 2, EventPhase.upcoming),
    ('ends exactly now', -minute, Duration.zero, EventPhase.ended),
    ('ended before', -minute * 2, -minute, EventPhase.ended),
  ];
  for (final (name, start, end, phase) in cases) {
    test('phaseAt: $name is $phase', () {
      final event = webEvent('1', startOffset: start, endOffset: end);

      expect(event.phaseAt(testNow), phase);
    });
  }
}
