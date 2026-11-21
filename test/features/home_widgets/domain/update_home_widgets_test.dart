import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/dashboard/domain/note_result.dart';
import 'package:hoyo_aio/features/home_widgets/domain/update_home_widgets.dart';

import '../_support/widget_fixtures.dart';

void main() {
  test('publishes a snapshot of cached roles with today check-ins', () async {
    final history = FakeCheckInHistory(
      records: [record(Game.genshin, CheckInResult.claimed)],
    );
    final bridge = FakeHomeWidgetBridge();
    final update = UpdateHomeWidgets(
      FakeNotesRepository({1: NoteResult(note: genshinNote)}),
      history,
      FakeWidgetConfigRepository([config()]),
      bridge,
      () => DateTime(2026, 11, 21, 23, 59),
    );

    final snapshot = await update(
      roles: [genshinRole, starRailRole],
      checkInGames: {Game.genshin, Game.zzz},
      labels: testLabels,
    );

    expect(history.requestedDays, ['2026-11-21']);
    expect(snapshot.roles.map((r) => r.roleId), [1]);
    expect(snapshot.checkIn.done, 1);
    expect(snapshot.checkIn.total, 2);
    expect(snapshot.widgets, [config()]);
    expect(bridge.published, [snapshot]);
  });
}
