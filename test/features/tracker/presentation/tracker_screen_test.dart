import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/tracker/data/gacha_repository_impl.dart';
import 'package:hoyo_aio/features/tracker/presentation/tracker_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../_support/tracker_support.dart';

void main() {
  late FakeGachaRepository repository;
  late PlatformRecorder platform;

  setUp(() {
    repository = FakeGachaRepository();
    platform = PlatformRecorder();
  });

  Future<void> pump(WidgetTester tester, {Game game = Game.genshin}) async {
    useTallSurface(tester);
    platform.install(tester);
    await pumpScreen(
      tester,
      TrackerScreen(game: game),
      overrides: [
        gachaRepositoryProvider.overrideWithValue(repository),
        ...clockOverrides(),
      ],
    );
  }

  Finder sheetImportButton() => find.text('Paste History Link').last;

  group('empty state', () {
    testWidgets('shows the import card when there are no records', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Wish Tracker'), findsOneWidget);
      expect(find.text('Import your history'), findsOneWidget);
    });

    testWidgets('invalid link in the paste sheet shows an error', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text('Paste History Link'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'not a link');
      await tester.tap(sheetImportButton());
      await tester.pumpAndSettle();

      expect(find.text('That is not a history link from the game.'), findsOne);
      expect(repository.imported, isEmpty);
      expect(platform.clipboard, isEmpty);
    });

    testWidgets('valid link clears field and clipboard, closes the sheet', (
      tester,
    ) async {
      await pump(tester, game: Game.zzz);
      await tester.tap(find.text('Paste History Link'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), genshinLink());
      await tester.tap(sheetImportButton());
      await tester.pumpAndSettle();

      expect(repository.imported, [genshinLink()]);
      expect(repository.syncCalls, [Game.genshin]);
      expect(platform.clipboard, ['']);
      expect(find.text('Paste the history link'), findsNothing);
      expect(find.text('Wish Tracker'), findsOneWidget);
    });

    testWidgets('sync error during import is shown in the sheet', (
      tester,
    ) async {
      repository.syncError = const NetworkException();
      await pump(tester);
      await tester.tap(find.text('Paste History Link'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), genshinLink());
      await tester.tap(sheetImportButton());
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration?.errorText, isNotNull);
      expect(find.text('Paste the history link'), findsOneWidget);
    });

    testWidgets('paste button fills the field from the clipboard', (
      tester,
    ) async {
      platform.clipboardText = 'pasted text';
      await pump(tester);
      await tester.tap(find.text('Paste History Link'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Paste'));
      await tester.pumpAndSettle();

      expect(find.text('pasted text'), findsOneWidget);
    });
  });

  group('data state', () {
    setUp(() {
      repository.records[Game.genshin] = [
        for (var id = 1; id <= 20; id++)
          gachaRecord(
            id,
            rank: switch (id) {
              10 || 15 => 5,
              5 => 4,
              _ => 3,
            },
            name: switch (id) {
              10 => 'Diluc',
              15 => 'Furina',
              _ => 'Item $id',
            },
          ),
        gachaRecord(30, banner: '302'),
      ];
    });

    testWidgets('shows pity hero, stats and 5 star history', (tester) async {
      await pump(tester);

      expect(find.text('5★ PITY · CHARACTER'), findsOneWidget);
      expect(find.text('5'), findsWidgets);
      expect(find.text('Next 5★ guaranteed'), findsNothing);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('7.5'), findsOneWidget);
      expect(find.text('0 of 1'), findsOneWidget);
      expect(find.text('All 2'), findsOneWidget);
      expect(find.text('Furina'), findsOneWidget);
      expect(find.text('Diluc'), findsOneWidget);
      expect(find.text('Lost 50/50'), findsOneWidget);
      expect(find.text('Soft pity 74'), findsOneWidget);
    });

    testWidgets('banner tab without 5 stars shows the empty line', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Weapon'));
      await tester.pumpAndSettle();

      expect(find.text('No 5★ on this banner yet.'), findsOneWidget);
      expect(find.text('–'), findsNWidgets(2));
    });

    testWidgets('game chip switches the tracker', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Warps'));
      await tester.pumpAndSettle();

      expect(find.text('Warp Tracker'), findsOneWidget);
      expect(find.text('Import your history'), findsOneWidget);
    });

    testWidgets('refresh shows progress while syncing', (tester) async {
      repository.syncGate = Completer<void>();
      await pump(tester);

      await tester.tap(find.byIcon(LucideIcons.refreshCw));
      await tester.pump();

      expect(find.text('Fetched 7 records…'), findsOneWidget);
      repository.syncGate?.complete();
      await tester.pumpAndSettle();
      expect(find.text('Fetched 7 records…'), findsNothing);
    });

    testWidgets('expired link on refresh opens the import sheet', (
      tester,
    ) async {
      repository.syncError = const AuthkeyExpiredException();
      await pump(tester);

      await tester.tap(find.byIcon(LucideIcons.refreshCw));
      await tester.pumpAndSettle();

      expect(find.text('Paste the history link'), findsOneWidget);
    });

    testWidgets('network error on refresh shows a snackbar', (tester) async {
      repository.syncError = const NetworkException();
      await pump(tester);

      await tester.tap(find.byIcon(LucideIcons.refreshCw));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
