import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/app/flavor_provider.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/has_accounts_provider.dart';
import 'package:hoyo_aio/features/background/background_dispatcher.dart';
import 'package:hoyo_aio/features/background/data/background_settings_repository_impl.dart';
import 'package:hoyo_aio/features/background/presentation/providers/background_sync_provider.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_record.dart';
import 'package:hoyo_aio/features/checkin/presentation/providers/check_in_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workmanager/workmanager.dart';

class MockWorkmanager extends Mock implements Workmanager {}

void main() {
  final now = DateTime(2026, 11, 5, 10);
  late MockWorkmanager workmanager;

  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(Constraints(networkType: NetworkType.connected));
    registerFallbackValue(ExistingPeriodicWorkPolicy.update);
    registerFallbackValue(ExistingWorkPolicy.replace);
  });

  setUp(() {
    workmanager = MockWorkmanager();
    when(() => workmanager.cancelAll()).thenAnswer((_) async {});
    when(() => workmanager.cancelByUniqueName(any())).thenAnswer((_) async {});
    when(
      () => workmanager.registerPeriodicTask(
        any(),
        any(),
        frequency: any(named: 'frequency'),
        constraints: any(named: 'constraints'),
        existingWorkPolicy: any(named: 'existingWorkPolicy'),
        inputData: any(named: 'inputData'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => workmanager.registerOneOffTask(
        any(),
        any(),
        initialDelay: any(named: 'initialDelay'),
        constraints: any(named: 'constraints'),
        existingWorkPolicy: any(named: 'existingWorkPolicy'),
        inputData: any(named: 'inputData'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> sync({
    required bool hasAccounts,
    int refreshMinutes = 30,
    Set<Game> games = const {Game.genshin},
  }) async {
    final container = ProviderContainer(
      overrides: [
        flavorProvider.overrideWithValue(Flavor.dev),
        clockProvider.overrideWithValue(() => now),
        hasAccountsProvider.overrideWith((_) => Stream.value(hasAccounts)),
        refreshMinutesProvider.overrideWith(
          (_) => Stream.value(refreshMinutes),
        ),
        autoCheckInSettingsProvider.overrideWith(
          (_) => Stream.value(
            AutoCheckInSettings(games: games, runAtMinutes: 9 * 60),
          ),
        ),
        workmanagerProvider.overrideWith((_) async => workmanager),
      ],
    );
    addTearDown(container.dispose);
    container.listen(backgroundSyncProvider, (_, _) {});
    await container.read(hasAccountsProvider.future);
    await container.read(refreshMinutesProvider.future);
    await container.read(autoCheckInSettingsProvider.future);
    await container.read(backgroundSyncProvider.future);
  }

  test('cancels every task when there are no accounts', () async {
    await sync(hasAccounts: false);

    verify(() => workmanager.cancelAll()).called(1);
    verifyNever(
      () => workmanager.registerPeriodicTask(
        any(),
        any(),
        frequency: any(named: 'frequency'),
        constraints: any(named: 'constraints'),
        existingWorkPolicy: any(named: 'existingWorkPolicy'),
        inputData: any(named: 'inputData'),
      ),
    );
  });

  test('registers the periodic refresh and the next check-in', () async {
    await sync(hasAccounts: true, refreshMinutes: 60);

    verify(
      () => workmanager.registerPeriodicTask(
        BackgroundTasks.notesRefresh,
        BackgroundTasks.notesRefresh,
        frequency: const Duration(minutes: 60),
        constraints: any(named: 'constraints'),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        inputData: {BackgroundTasks.flavorKey: 'dev'},
      ),
    ).called(1);
    verify(
      () => workmanager.registerOneOffTask(
        BackgroundTasks.autoCheckIn,
        BackgroundTasks.autoCheckIn,
        initialDelay: const Duration(hours: 23),
        constraints: any(named: 'constraints'),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        inputData: {BackgroundTasks.flavorKey: 'dev'},
      ),
    ).called(1);
    verifyNever(() => workmanager.cancelAll());
  });

  test('never schedules the refresh below 15 minutes', () async {
    await sync(hasAccounts: true, refreshMinutes: 5);

    verify(
      () => workmanager.registerPeriodicTask(
        any(),
        any(),
        frequency: const Duration(minutes: minRefreshMinutes),
        constraints: any(named: 'constraints'),
        existingWorkPolicy: any(named: 'existingWorkPolicy'),
        inputData: any(named: 'inputData'),
      ),
    ).called(1);
  });

  test('cancels the check-in task when no game has auto check-in', () async {
    await sync(hasAccounts: true, games: const {});

    verify(() => workmanager.cancelByUniqueName(BackgroundTasks.autoCheckIn))
        .called(1);
    verifyNever(
      () => workmanager.registerOneOffTask(
        any(),
        any(),
        initialDelay: any(named: 'initialDelay'),
        constraints: any(named: 'constraints'),
        existingWorkPolicy: any(named: 'existingWorkPolicy'),
        inputData: any(named: 'inputData'),
      ),
    );
  });

  test('runRefreshNowInBackground queues a one-off refresh', () async {
    await runRefreshNowInBackground(workmanager, Flavor.prod);

    verify(
      () => workmanager.registerOneOffTask(
        '${BackgroundTasks.notesRefresh}.now',
        BackgroundTasks.notesRefresh,
        initialDelay: any(named: 'initialDelay'),
        constraints: any(named: 'constraints'),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        inputData: {BackgroundTasks.flavorKey: 'prod'},
      ),
    ).called(1);
  });
}
