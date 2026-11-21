import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/features/home_widgets/data/home_widget_bridge_impl.dart';
import 'package:hoyo_aio/features/home_widgets/domain/home_widget_repositories.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot_builder.dart';

import '../_support/widget_fixtures.dart';

const _channel = MethodChannel('home_widget');

WidgetSnapshot _snapshot() => WidgetSnapshotBuilder.build(
  notes: allNotes,
  checkInToday: const [],
  day: '2026-11-21',
  checkInTotal: 0,
  widgets: const [],
  labels: testLabels,
  now: fetchedAt,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<MethodCall> calls;
  Object? Function(MethodCall call) respond = (_) => null;

  setUp(() {
    calls = [];
    respond = (_) => null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          return respond(call);
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  const bridge = HomeWidgetBridgeImpl();

  group('publish', () {
    test('saves the snapshot JSON under the snapshot key on Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final snapshot = _snapshot();

      await bridge.publish(snapshot);

      expect(calls.first.method, 'setAppGroupId');
      expect(calls.first.arguments, {
        'groupId': HomeWidgetBridgeImpl.appGroupId,
      });
      final save = calls[1];
      expect(save.method, 'saveWidgetData');
      final args = save.arguments as Map<Object?, Object?>;
      expect(args['id'], HomeWidgetBridgeImpl.snapshotKey);
      expect(
        WidgetSnapshot.fromJson(
          jsonDecode(args['data']! as String) as Map<String, dynamic>,
        ),
        snapshot,
      );
    });

    test('requests an update for every Android receiver', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await bridge.publish(_snapshot());

      final updates = calls.where((c) => c.method == 'updateWidget').toList();
      expect([
        for (final c in updates)
          (c.arguments as Map<Object?, Object?>)['qualifiedAndroidName'],
      ], HomeWidgetBridgeImpl.androidReceivers);
    });

    test('requests a single WidgetKit reload on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await bridge.publish(_snapshot());

      final updates = calls.where((c) => c.method == 'updateWidget').toList();
      expect(updates, hasLength(1));
      expect(
        (updates.single.arguments as Map<Object?, Object?>)['ios'],
        HomeWidgetBridgeImpl.iosKind,
      );
    });
  });

  group('placed', () {
    test(
      'maps installed Android receivers to sizes and skips unknown',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        respond = (call) => [
          {
            'widgetId': 11,
            'androidClassName': 'com.hoyoaio.app.widget.SmallWidgetReceiver',
          },
          {
            'widgetId': 12,
            'androidClassName': 'com.hoyoaio.app.widget.MediumWidgetReceiver',
          },
          {
            'widgetId': 13,
            'androidClassName': 'com.hoyoaio.app.widget.LargeWidgetReceiver',
          },
          {'widgetId': 14, 'androidClassName': 'com.other.Receiver'},
          {'androidClassName': 'com.hoyoaio.app.widget.SmallWidgetReceiver'},
        ];

        final placed = await bridge.placed();

        expect(
          [for (final p in placed) (p.widgetId, p.size)],
          [
            (11, HomeWidgetSize.small),
            (12, HomeWidgetSize.medium),
            (13, HomeWidgetSize.large),
          ],
        );
      },
    );

    test('returns nothing on iOS without calling the channel', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      expect(await bridge.placed(), isEmpty);
      expect(calls, isEmpty);
    });
  });

  group('pinning', () {
    test(
      'canPin is true only on Android when the launcher supports it',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        respond = (_) => true;
        expect(await bridge.canPin(), isTrue);

        respond = (_) => null;
        expect(await bridge.canPin(), isFalse);

        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        respond = (_) => true;
        expect(await bridge.canPin(), isFalse);
      },
    );

    test('pin requests the receiver for the chosen size', () async {
      await bridge.pin(HomeWidgetSize.medium);

      expect(calls.single.method, 'requestPinWidget');
      expect(
        (calls.single.arguments
            as Map<Object?, Object?>)['qualifiedAndroidName'],
        'com.hoyoaio.app.widget.MediumWidgetReceiver',
      );
    });
  });
}
