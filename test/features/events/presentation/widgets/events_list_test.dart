import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/design_system/components/app_toggle.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/events/data/events_repository_impl.dart';
import 'package:hoyo_aio/features/events/domain/web_event.dart';
import 'package:hoyo_aio/features/events/presentation/widgets/events_list.dart';
import 'package:material_ui/material_ui.dart';

import '../../../codes/_support/community_fakes.dart';
import '../../../tracker/_support/tracker_support.dart';

void main() {
  late FakeEventsRepository repository;
  late PlatformRecorder platform;

  final events = [
    webEvent('running1', unread: true),
    webEvent('running2', game: Game.zzz, summary: ''),
    webEvent(
      'upcoming',
      startOffset: const Duration(days: 2),
      endOffset: const Duration(days: 5),
    ),
    webEvent(
      'endedOld',
      startOffset: const Duration(days: -9),
      endOffset: const Duration(days: -5),
    ),
    webEvent(
      'endedNew',
      startOffset: const Duration(days: -4),
      endOffset: const Duration(days: -1),
    ),
  ];

  setUp(() {
    repository = FakeEventsRepository(events);
    platform = PlatformRecorder();
  });

  Future<void> pump(WidgetTester tester, List<WebEvent> shown) async {
    useTallSurface(tester);
    platform.install(tester);
    await pumpScreen(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: EventsList(events: shown, now: testNow),
        ),
      ),
      overrides: [eventsRepositoryProvider.overrideWithValue(repository)],
    );
  }

  Future<void> tapPhase(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('running tab shows a featured card then compact cards', (
    tester,
  ) async {
    await pump(tester, events);

    expect(find.text('Event running1'), findsOneWidget);
    expect(find.text('Summary text'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.textContaining('Ends in'), findsNWidgets(2));
    expect(find.text('Event running2'), findsOneWidget);
    expect(find.text('Event upcoming'), findsNothing);
    expect(find.text('Event endedNew'), findsNothing);
  });

  testWidgets('upcoming tab shows events that have not started', (
    tester,
  ) async {
    await pump(tester, events);

    await tapPhase(tester, 'Upcoming');

    expect(find.text('Event upcoming'), findsOneWidget);
    expect(find.textContaining('Starts in'), findsOneWidget);
    expect(find.text('Event running1'), findsNothing);
  });

  testWidgets('ended tab lists newest ended first without remind toggle', (
    tester,
  ) async {
    await pump(tester, events);

    await tapPhase(tester, 'Ended');

    final newer = tester.getTopLeft(find.text('Event endedNew'));
    final older = tester.getTopLeft(find.text('Event endedOld'));
    expect(newer.dy, lessThan(older.dy));
    expect(find.byType(AppToggle), findsNothing);
    expect(find.textContaining('Ended '), findsNWidgets(2));
  });

  testWidgets('empty phase shows the empty line', (tester) async {
    await pump(tester, const []);

    expect(find.text('No events here.'), findsOneWidget);
  });

  testWidgets('remind toggle stores the reminder', (tester) async {
    await pump(tester, events);

    await tester.tap(find.byType(AppToggle).first);
    await tester.tap(find.byType(AppToggle).last);
    await tester.pumpAndSettle();

    expect(repository.reminders, {'running1': true, 'running2': true});
  });

  testWidgets('open and compact tap launch the event page', (tester) async {
    await pump(tester, events);

    await tester.tap(find.text('Open'));
    await tester.tap(find.text('Event running2'));
    await tester.pumpAndSettle();

    expect(platform.launched, [
      eventUri(events[0]).toString(),
      eventUri(events[1]).toString(),
    ]);
  });
}
