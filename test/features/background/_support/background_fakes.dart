import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/app/flavor_provider.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/logging/app_logger.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/accounts/data/account_repository_impl.dart';
import 'package:hoyo_aio/features/accounts/domain/account_repository.dart';
import 'package:hoyo_aio/features/accounts/domain/account_summary.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_record.dart';
import 'package:hoyo_aio/features/checkin/domain/run_auto_checkin.dart';
import 'package:hoyo_aio/features/checkin/presentation/providers/check_in_provider.dart';
import 'package:hoyo_aio/features/codes/data/codes_repository_impl.dart';
import 'package:hoyo_aio/features/codes/domain/codes_repository.dart';
import 'package:hoyo_aio/features/dashboard/data/notes_repository_impl.dart';
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';
import 'package:hoyo_aio/features/dashboard/domain/note_result.dart';
import 'package:hoyo_aio/features/dashboard/domain/notes_repository.dart';
import 'package:hoyo_aio/features/dashboard/domain/stamina.dart';
import 'package:hoyo_aio/features/dashboard/domain/task_progress.dart';
import 'package:hoyo_aio/features/events/data/events_repository_impl.dart';
import 'package:hoyo_aio/features/events/domain/events_repository.dart';
import 'package:hoyo_aio/features/home_widgets/domain/update_home_widgets.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/providers/widget_sync_provider.dart';
import 'package:hoyo_aio/features/notifications/data/notification_service.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_kind.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_settings.dart';
import 'package:hoyo_aio/features/notifications/domain/reschedule_notifications.dart';
import 'package:hoyo_aio/features/notifications/presentation/providers/notification_sync_provider.dart';
import 'package:hoyo_aio/features/tracker/data/gacha_repository_impl.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_repository.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockCodesRepository extends Mock implements CodesRepository {}

class MockEventsRepository extends Mock implements EventsRepository {}

class MockGachaRepository extends Mock implements GachaRepository {}

class MockRunAutoCheckIn extends Mock implements RunAutoCheckIn {}

class MockRescheduleNotifications extends Mock
    implements RescheduleNotifications {}

class MockUpdateHomeWidgets extends Mock implements UpdateHomeWidgets {}

class FakeWidgetSnapshot extends Fake implements WidgetSnapshot {}

class ShownNotification {
  const ShownNotification(
    this.id,
    this.kind,
    this.title,
    this.body,
    this.payload,
  );

  final int id;
  final NotificationKind kind;
  final String title;
  final String body;
  final String? payload;
}

class RecordingShowService extends NotificationService {
  RecordingShowService() : super(FlutterLocalNotificationsPlugin());

  final shown = <ShownNotification>[];

  @override
  Future<void> showNow({
    required int id,
    required NotificationKind kind,
    required String title,
    required String body,
    String? payload,
    List<(String, String)> actions = const [],
  }) async => shown.add(ShownNotification(id, kind, title, body, payload));
}

class FakeNotesRepository implements NotesRepository {
  FakeNotesRepository({this.failing = const {}});

  final Set<int> failing;
  final refreshed = <SavedRole>[];

  @override
  Future<NoteResult?> cached(SavedRole role) async => null;

  @override
  Future<NoteResult> refresh(SavedRole role) async {
    refreshed.add(role);
    if (failing.contains(role.id)) throw const NetworkException();
    return NoteResult(note: genshinNote());
  }
}

final jobsNow = DateTime(2026, 11, 5, 10);

GameNote genshinNote() => GameNote.genshin(
  fetchedAt: jobsNow,
  resin: Stamina(
    current: 100,
    max: 200,
    fetchedAt: jobsNow,
    recoveryInterval: const Duration(minutes: 8),
  ),
  realmCurrency: Stamina(
    current: 0,
    max: 2400,
    fetchedAt: jobsNow,
    recoveryInterval: const Duration(minutes: 2),
  ),
  commissions: const TaskProgress(done: 0, total: 4),
  commissionBonusClaimed: false,
  weeklyBossDiscountsLeft: const TaskProgress(done: 0, total: 3),
  transformerReadyAt: null,
  expeditions: const [],
  maxExpeditions: 5,
);

SavedRole role(
  int id,
  Game game, {
  String accountId = '800000001',
  bool enabled = true,
}) => SavedRole(
  id: id,
  accountId: accountId,
  game: game,
  uid: '80000000$id',
  server: 'os_asia',
  nickname: 'Tester $id',
  level: 60,
  enabled: enabled,
);

AccountSummary account(
  String id,
  List<SavedRole> roles, {
  AccountStatus status = AccountStatus.valid,
}) => AccountSummary(
  id: id,
  nickname: 'Player $id',
  status: status,
  updatedAt: jobsNow,
  roles: roles,
);

class JobsHarness {
  JobsHarness({
    required this.accountSnapshots,
    FakeNotesRepository? notes,
    DateTime? now,
  }) : notes = notes ?? FakeNotesRepository(),
       now = now ?? jobsNow {
    var call = 0;
    when(accounts.watchAccounts).thenAnswer((_) {
      final index = call < accountSnapshots.length
          ? call
          : accountSnapshots.length - 1;
      call++;
      return Stream.value(accountSnapshots[index]);
    });
    when(codes.refresh).thenAnswer((_) async => const []);
    when(events.refresh).thenAnswer((_) async => const []);
    when(() => events.takeEndingSoon(any())).thenAnswer((_) async => const []);
    when(() => gacha.linkExpiresAt(any())).thenAnswer((_) async => null);
    when(
      () => reschedule(
        roles: any(named: 'roles'),
        settings: any(named: 'settings'),
        localeCode: any(named: 'localeCode'),
      ),
    ).thenAnswer((_) async => const []);
    when(
      () => widgets(
        roles: any(named: 'roles'),
        checkInGames: any(named: 'checkInGames'),
        labels: any(named: 'labels'),
      ),
    ).thenAnswer((_) async => FakeWidgetSnapshot());
    container = ProviderContainer(
      overrides: [
        flavorProvider.overrideWithValue(Flavor.dev),
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => this.now),
        appLoggerProvider.overrideWithValue(
          AppLogger(verbose: false, output: logOutput),
        ),
        accountRepositoryProvider.overrideWithValue(accounts),
        notesRepositoryProvider.overrideWithValue(this.notes),
        codesRepositoryProvider.overrideWithValue(codes),
        eventsRepositoryProvider.overrideWithValue(events),
        gachaRepositoryProvider.overrideWithValue(gacha),
        runAutoCheckInProvider.overrideWithValue(run),
        rescheduleNotificationsProvider.overrideWithValue(reschedule),
        updateHomeWidgetsProvider.overrideWithValue(widgets),
        notificationServiceProvider.overrideWithValue(service),
      ],
    );
  }

  final List<List<AccountSummary>> accountSnapshots;
  final FakeNotesRepository notes;
  DateTime now;
  final db = AppDatabase(NativeDatabase.memory());
  final logOutput = MemoryOutput();
  final accounts = MockAccountRepository();
  final codes = MockCodesRepository();
  final events = MockEventsRepository();
  final gacha = MockGachaRepository();
  final run = MockRunAutoCheckIn();
  final reschedule = MockRescheduleNotifications();
  final widgets = MockUpdateHomeWidgets();
  final service = RecordingShowService();
  late final ProviderContainer container;

  List<String> get warnings => [
    for (final event in logOutput.buffer) ...event.lines,
  ];

  Future<void> dispose() async {
    container.dispose();
    await db.close();
  }
}

void registerJobFallbacks() {
  registerFallbackValue(Duration.zero);
  registerFallbackValue(Game.genshin);
  registerFallbackValue(const NotificationSettings());
  registerFallbackValue(<SavedRole>[]);
  registerFallbackValue(<Game>{});
  registerFallbackValue(CheckInRun(runAt: jobsNow, records: const []));
}
