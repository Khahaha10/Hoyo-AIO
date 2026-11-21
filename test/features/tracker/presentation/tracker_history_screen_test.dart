import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/tracker/data/gacha_repository_impl.dart';
import 'package:hoyo_aio/features/tracker/presentation/tracker_history_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../_support/tracker_support.dart';

void main() {
  late FakeGachaRepository repository;

  setUp(() {
    repository = FakeGachaRepository(
      records: {
        Game.genshin: [
          gachaRecord(
            5,
            rank: 5,
            name: 'Diluc',
            time: '2026-11-20 11:30:00',
            itemType: 'Character',
          ),
          gachaRecord(4, time: '2026-11-20 11:30:00', name: 'Sword, "Cool"'),
          gachaRecord(3, rank: 4, name: 'Bennett', time: '2026-11-19 09:00:00'),
          gachaRecord(2, time: 'bad', name: 'Odd Time'),
          gachaRecord(1, name: 'Other Banner', banner: '302'),
        ],
      },
    );
  });

  Future<void> pump(WidgetTester tester) async {
    useTallSurface(tester);
    PlatformRecorder().install(tester);
    await pumpScreen(
      tester,
      const TrackerHistoryScreen(game: Game.genshin, banner: '301'),
      overrides: [
        gachaRepositoryProvider.overrideWithValue(repository),
        ...clockOverrides(),
      ],
    );
  }

  testWidgets('shows header, batches and 5 and 4 star rows by default', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Wish History'), findsOneWidget);
    expect(find.text('Character · 4 wishes'), findsOneWidget);
    expect(find.text('Diluc'), findsOneWidget);
    expect(find.text('Character · 11:30'), findsOneWidget);
    expect(find.text('Bennett'), findsOneWidget);
    expect(find.text('Odd Time'), findsNothing);
    expect(find.text('Other Banner'), findsNothing);
    expect(find.text('NOV 20 · 2× PULL'), findsOneWidget);
    expect(find.text('pity'), findsWidgets);
  });

  testWidgets('rarity chips filter rows', (tester) async {
    await pump(tester);

    await tester.tap(find.text('3★'));
    await tester.pumpAndSettle();
    expect(find.text('Odd Time'), findsOneWidget);
    expect(find.text('BAD · 1× PULL'), findsOneWidget);

    for (final rank in ['3★', '4★', '5★']) {
      await tester.tap(find.text(rank).first);
      await tester.pumpAndSettle();
    }
    expect(find.text('No records for these rarities.'), findsOneWidget);
  });

  testWidgets('sync card says the link expired when none is stored', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Link expired'), findsOneWidget);
    expect(find.byIcon(LucideIcons.unlink), findsOneWidget);
  });

  testWidgets('sync card shows remaining link time when valid', (tester) async {
    repository.expiry = testNow.add(const Duration(hours: 5));
    await pump(tester);

    expect(find.textContaining('Link valid for'), findsOneWidget);
    expect(find.byIcon(LucideIcons.link), findsOneWidget);
  });

  testWidgets('update syncs and then shows the sync time', (tester) async {
    repository.syncGate = Completer<void>();
    await pump(tester);

    await tester.tap(find.text('Update'));
    await tester.pump();
    expect(find.text('Fetched 7 records…'), findsOneWidget);

    repository.syncGate?.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('Synced'), findsOneWidget);
  });

  testWidgets('update with an expired link opens the import sheet', (
    tester,
  ) async {
    repository.syncError = const AuthkeyExpiredException();
    await pump(tester);

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(find.text('Paste the history link'), findsOneWidget);
  });

  testWidgets('update with a network error shows a snackbar', (tester) async {
    repository.syncError = const NetworkException();
    await pump(tester);

    await tester.tap(find.text('Update'));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('export shares a CSV of the banner', (tester) async {
    final temp = Directory.systemTemp.createTempSync('tracker_csv');
    addTearDown(() => temp.deleteSync(recursive: true));
    final shared = <Map<Object?, Object?>>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
    messenger
      ..setMockMethodCallHandler(pathChannel, (_) async => temp.path)
      ..setMockMethodCallHandler(shareChannel, (call) async {
        shared.add(call.arguments as Map<Object?, Object?>);
        return 'dev.fluttercommunity.plus/share/success';
      });
    addTearDown(() {
      messenger
        ..setMockMethodCallHandler(pathChannel, null)
        ..setMockMethodCallHandler(shareChannel, null);
    });
    await pump(tester);

    await tester.runAsync(() async {
      await tester.tap(find.byIcon(LucideIcons.download));
      for (var i = 0; i < 50 && shared.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });

    final paths = (shared.single['paths'] as List<Object?>).cast<String>();
    final csv = File(paths.single).readAsStringSync();
    expect(paths.single, endsWith('genshin_301.csv'));
    expect(csv, startsWith('time,name,item_type,rank,banner,id\n'));
    expect(csv, contains('"Sword, ""Cool"""'));
    expect(csv, isNot(contains('Other Banner')));
  });
}
