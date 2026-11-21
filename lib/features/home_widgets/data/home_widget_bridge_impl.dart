import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hoyo_aio/features/home_widgets/domain/home_widget_repositories.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_widget_bridge_impl.g.dart';

class HomeWidgetBridgeImpl implements HomeWidgetBridge {
  const HomeWidgetBridgeImpl();

  static const appGroupId = 'group.com.hoyoaio.app';
  static const snapshotKey = 'hoyo_aio_snapshot';
  static const iosKind = 'HoYoWidgets';
  static const androidReceivers = [
    'com.hoyoaio.app.widget.SmallWidgetReceiver',
    'com.hoyoaio.app.widget.MediumWidgetReceiver',
    'com.hoyoaio.app.widget.LargeWidgetReceiver',
  ];

  @override
  Future<void> publish(WidgetSnapshot snapshot) async {
    await HomeWidget.setAppGroupId(appGroupId);
    await HomeWidget.saveWidgetData<String>(
      snapshotKey,
      jsonEncode(snapshot.toJson()),
    );
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await HomeWidget.updateWidget(iOSName: iosKind);
      return;
    }
    for (final receiver in androidReceivers) {
      await HomeWidget.updateWidget(qualifiedAndroidName: receiver);
    }
  }

  @override
  Future<List<PlacedWidget>> placed() async {
    if (defaultTargetPlatform != TargetPlatform.android) return const [];
    final installed = await HomeWidget.getInstalledWidgets();
    return [
      for (final widget in installed)
        if ((widget.androidWidgetId, _sizeOf(widget.androidClassName)) case (
          final id?,
          final size?,
        ))
          PlacedWidget(widgetId: id, size: size),
    ];
  }

  @override
  Future<bool> canPin() async =>
      defaultTargetPlatform == TargetPlatform.android &&
      (await HomeWidget.isRequestPinWidgetSupported() ?? false);

  @override
  Future<void> pin(HomeWidgetSize size) => HomeWidget.requestPinWidget(
    qualifiedAndroidName: androidReceivers[size.index],
  );

  static HomeWidgetSize? _sizeOf(String? className) => switch (className) {
    final name? when name.endsWith('SmallWidgetReceiver') =>
      HomeWidgetSize.small,
    final name? when name.endsWith('MediumWidgetReceiver') =>
      HomeWidgetSize.medium,
    final name? when name.endsWith('LargeWidgetReceiver') =>
      HomeWidgetSize.large,
    _ => null,
  };
}

@Riverpod(keepAlive: true)
HomeWidgetBridge homeWidgetBridge(Ref ref) => const HomeWidgetBridgeImpl();
