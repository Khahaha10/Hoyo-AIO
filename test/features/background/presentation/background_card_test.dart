import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/app/flavor_provider.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/platform/system_settings.dart';
import 'package:hoyo_aio/features/background/background_dispatcher.dart';
import 'package:hoyo_aio/features/background/data/background_settings_repository_impl.dart';
import 'package:hoyo_aio/features/background/domain/background_settings_repository.dart';
import 'package:hoyo_aio/features/background/presentation/background_card.dart';
import 'package:hoyo_aio/features/background/presentation/providers/background_sync_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workmanager/workmanager.dart';

class MockWorkmanager extends Mock implements Workmanager {}

class FakeBackgroundSettingsRepository implements BackgroundSettingsRepository {
  final saved = <int>[];

  @override
  Stream<int> watchRefreshMinutes() => const Stream.empty();

  @override
  Future<void> setRefreshMinutes(int minutes) async => saved.add(minutes);
}

class FakeSystemSettings extends SystemSettings {
  var opened = 0;
  var ignoredChecks = 0;

  @override
  Future<bool> isIgnoringBatteryOptimizations() async {
    ignoredChecks++;
    return false;
  }

  @override
  Future<void> openBatteryOptimizationSettings() async => opened++;
}

void main() {
  late FakeBackgroundSettingsRepository repository;
  late FakeSystemSettings system;
  late MockWorkmanager workmanager;

  setUpAll(() => registerFallbackValue(ExistingWorkPolicy.replace));

  setUp(() {
    repository = FakeBackgroundSettingsRepository();
    system = FakeSystemSettings();
    workmanager = MockWorkmanager();
    when(
      () => workmanager.registerOneOffTask(
        any(),
        any(),
        inputData: any(named: 'inputData'),
        existingWorkPolicy: any(named: 'existingWorkPolicy'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpCard(
    WidgetTester tester, {
    int? minutes = 30,
    bool batteryIgnored = false,
    Flavor flavor = Flavor.dev,
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flavorProvider.overrideWithValue(flavor),
          refreshMinutesProvider.overrideWith(
            (_) => minutes == null
                ? const Stream<int>.empty()
                : Stream.value(minutes),
          ),
          batteryOptimizationIgnoredProvider.overrideWith(
            (ref) async => batteryIgnored,
          ),
          backgroundSettingsRepositoryProvider.overrideWithValue(repository),
          systemSettingsProvider.overrideWithValue(system),
          workmanagerProvider.overrideWith((_) async => workmanager),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: BackgroundCard()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 10));
  }

  testWidgets('renders nothing until the interval is known', (tester) async {
    await pumpCard(tester, minutes: null);

    expect(find.text('Background Refresh'), findsNothing);
    await drain(tester);
  });

  testWidgets('saves the chosen refresh interval', (tester) async {
    await pumpCard(tester);

    expect(find.text('Background Refresh'), findsOneWidget);
    await tester.tap(find.text('60m'));
    await tester.pump();

    expect(repository.saved, [60]);
    await drain(tester);
  });

  testWidgets('dev flavor can run a background refresh now', (tester) async {
    await pumpCard(tester);

    await tester.tap(find.text('Run Background Refresh Now'));
    await tester.pump();

    verify(
      () => workmanager.registerOneOffTask(
        '${BackgroundTasks.notesRefresh}.now',
        BackgroundTasks.notesRefresh,
        inputData: {BackgroundTasks.flavorKey: 'dev'},
        existingWorkPolicy: ExistingWorkPolicy.replace,
      ),
    ).called(1);
    await drain(tester);
  });

  testWidgets('prod flavor hides the run-now row', (tester) async {
    await pumpCard(tester, flavor: Flavor.prod);

    expect(find.text('Run Background Refresh Now'), findsNothing);
    await drain(tester);
  });

  testWidgets('hides the battery row when optimization is off', (tester) async {
    await pumpCard(tester, batteryIgnored: true);

    expect(find.text('Battery Optimization'), findsNothing);
    await drain(tester);
  });

  testWidgets('battery sheet opens system settings and closes', (tester) async {
    await pumpCard(tester);

    await tester.tap(find.text('Battery Optimization'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Let HoYo AIO Run in Background'), findsOneWidget);

    await tester.tap(find.text('Open Battery Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(system.opened, 1);
    expect(find.text('Let HoYo AIO Run in Background'), findsNothing);
    await drain(tester);
  });
}
