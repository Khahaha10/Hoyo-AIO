import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/platform/system_settings.dart';

const _channel = MethodChannel('com.hoyoaio.app/system');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <String>[];
  const settings = SystemSettings();

  void answer(Object? Function(MethodCall call) reply) =>
      messenger.setMockMethodCallHandler(_channel, (call) async {
        calls.add(call.method);
        return reply(call);
      });

  setUp(calls.clear);

  tearDown(() {
    messenger.setMockMethodCallHandler(_channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('non-Android platforms never call the channel', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    answer((_) => false);

    final ignored = await settings.isIgnoringBatteryOptimizations();
    await settings.openBatteryOptimizationSettings();

    expect(ignored, isTrue);
    expect(calls, isEmpty);
  });

  test('Android reads the battery optimization state', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    answer((_) => false);

    final ignored = await settings.isIgnoringBatteryOptimizations();

    expect(ignored, isFalse);
    expect(calls, ['isIgnoringBatteryOptimizations']);
  });

  test('Android treats null, errors and a missing plugin as ignored', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    answer((_) => null);
    expect(await settings.isIgnoringBatteryOptimizations(), isTrue);
    answer((_) => throw PlatformException(code: 'x'));
    expect(await settings.isIgnoringBatteryOptimizations(), isTrue);
    messenger.setMockMethodCallHandler(_channel, null);
    expect(await settings.isIgnoringBatteryOptimizations(), isTrue);
  });

  test('Android opens battery settings and swallows errors', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    answer((_) => true);
    await settings.openBatteryOptimizationSettings();
    answer((_) => throw PlatformException(code: 'x'));
    await settings.openBatteryOptimizationSettings();

    expect(calls, [
      'openBatteryOptimizationSettings',
      'openBatteryOptimizationSettings',
    ]);
  });

  test('batteryOptimizationIgnored reads through the provider', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    answer((_) => false);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final ignored = await container.read(
      batteryOptimizationIgnoredProvider.future,
    );

    expect(container.read(systemSettingsProvider), isA<SystemSettings>());
    expect(ignored, isFalse);
  });
}
