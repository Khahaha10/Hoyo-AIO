import 'dart:math' as math;

import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/app/flavor_provider.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/has_accounts_provider.dart';
import 'package:hoyo_aio/features/background/background_dispatcher.dart';
import 'package:hoyo_aio/features/background/data/background_settings_repository_impl.dart';
import 'package:hoyo_aio/features/checkin/presentation/providers/check_in_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:workmanager/workmanager.dart';

part 'background_sync_provider.g.dart';

const minRefreshMinutes = 15;

@Riverpod(keepAlive: true)
Future<Workmanager> workmanager(Ref ref) async {
  final workmanager = Workmanager();
  await workmanager.initialize(backgroundDispatcher);
  return workmanager;
}

Future<void> runRefreshNowInBackground(
  Workmanager workmanager,
  Flavor flavor,
) => workmanager.registerOneOffTask(
  '${BackgroundTasks.notesRefresh}.now',
  BackgroundTasks.notesRefresh,
  inputData: {BackgroundTasks.flavorKey: flavor.name},
  existingWorkPolicy: ExistingWorkPolicy.replace,
);

@Riverpod(keepAlive: true)
Future<void> backgroundSync(Ref ref) async {
  final flavor = ref.watch(flavorProvider);
  final hasAccounts = ref.watch(hasAccountsProvider).value;
  final refreshMinutes = ref.watch(refreshMinutesProvider).value;
  final checkIn = ref.watch(autoCheckInSettingsProvider).value;
  if (hasAccounts == null || refreshMinutes == null || checkIn == null) {
    return;
  }
  final workmanager = await ref.watch(workmanagerProvider.future);
  if (!hasAccounts) {
    await workmanager.cancelAll();
    return;
  }
  final inputData = {BackgroundTasks.flavorKey: flavor.name};
  final network = Constraints(networkType: NetworkType.connected);
  await workmanager.registerPeriodicTask(
    BackgroundTasks.notesRefresh,
    BackgroundTasks.notesRefresh,
    frequency: Duration(minutes: math.max(minRefreshMinutes, refreshMinutes)),
    constraints: network,
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    inputData: inputData,
  );
  if (checkIn.games.isEmpty) {
    await workmanager.cancelByUniqueName(BackgroundTasks.autoCheckIn);
    return;
  }
  final now = ref.read(clockProvider)();
  await workmanager.registerOneOffTask(
    BackgroundTasks.autoCheckIn,
    BackgroundTasks.autoCheckIn,
    initialDelay: checkIn.nextRunAfter(now).difference(now),
    constraints: network,
    existingWorkPolicy: ExistingWorkPolicy.replace,
    inputData: inputData,
  );
}
