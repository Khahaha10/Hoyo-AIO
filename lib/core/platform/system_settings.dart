import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'system_settings.g.dart';

class SystemSettings {
  const SystemSettings();

  static const _channel = MethodChannel('com.hoyoaio.app/system');

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!_isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>(
            'isIgnoringBatteryOptimizations',
          ) ??
          true;
    } on PlatformException {
      return true;
    } on MissingPluginException {
      return true;
    }
  }

  Future<void> openBatteryOptimizationSettings() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('openBatteryOptimizationSettings');
    } on PlatformException {
      return;
    }
  }
}

@Riverpod(keepAlive: true)
SystemSettings systemSettings(Ref ref) => const SystemSettings();

@riverpod
Future<bool> batteryOptimizationIgnored(Ref ref) =>
    ref.watch(systemSettingsProvider).isIgnoringBatteryOptimizations();
