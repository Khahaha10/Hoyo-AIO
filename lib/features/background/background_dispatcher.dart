import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/app/flavor_provider.dart';
import 'package:hoyo_aio/app/provider_retry.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/features/background/background_jobs.dart';
import 'package:workmanager/workmanager.dart';

abstract final class BackgroundTasks {
  static const notesRefresh = 'com.hoyoaio.app.notesRefresh';
  static const autoCheckIn = 'com.hoyoaio.app.autoCheckIn';
  static const flavorKey = 'flavor';
}

@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    DartPluginRegistrant.ensureInitialized();
    final flavor =
        Flavor.values.asNameMap()[inputData?[BackgroundTasks.flavorKey]] ??
        Flavor.prod;
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [flavorProvider.overrideWithValue(flavor)],
    );
    final jobs = BackgroundJobs(container);
    try {
      switch (task) {
        case BackgroundTasks.notesRefresh:
          await jobs.refreshNotes();
        case BackgroundTasks.autoCheckIn:
          await jobs.autoCheckIn();
          if (await jobs.nextAutoCheckInDelay() case final delay?) {
            await Workmanager().registerOneOffTask(
              BackgroundTasks.autoCheckIn,
              BackgroundTasks.autoCheckIn,
              initialDelay: delay,
              constraints: Constraints(networkType: NetworkType.connected),
              existingWorkPolicy: ExistingWorkPolicy.append,
              inputData: inputData,
            );
          }
      }
      return true;
    } on AppException {
      return false;
    } finally {
      container.dispose();
    }
  });
}
