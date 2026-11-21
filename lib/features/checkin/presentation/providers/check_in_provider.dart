import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/selected_role_provider.dart';
import 'package:hoyo_aio/features/checkin/data/check_in_history_repository_impl.dart';
import 'package:hoyo_aio/features/checkin/data/check_in_repository_impl.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_month.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_record.dart';
import 'package:hoyo_aio/features/checkin/domain/run_auto_checkin.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'check_in_provider.g.dart';

@Riverpod(keepAlive: true)
List<SavedRole> checkInRoles(Ref ref) {
  final accounts = ref.watch(accountsProvider).value ?? const [];
  return [
    for (final healthy in [true, false])
      for (final account in accounts)
        if (account.needsAttention != healthy) ...account.enabledRoles,
  ];
}

@Riverpod(keepAlive: true)
List<Game> checkInGames(Ref ref) {
  final roles = ref.watch(checkInRolesProvider);
  return [
    for (final game in Game.values)
      if (roles.any((role) => role.game == game)) game,
  ];
}

@Riverpod(keepAlive: true)
class CheckInSelectedGame extends _$CheckInSelectedGame {
  @override
  Game? build() => null;

  void select(Game game) => state = game;
}

@Riverpod(keepAlive: true)
SavedRole? checkInRole(Ref ref) {
  final roles = ref.watch(checkInRolesProvider);
  final games = ref.watch(checkInGamesProvider);
  final dashboardRole = ref.watch(selectedRoleProvider);
  final chosen = ref.watch(checkInSelectedGameProvider);
  final game = games.contains(chosen)
      ? chosen
      : games.contains(dashboardRole?.game)
      ? dashboardRole?.game
      : games.firstOrNull;
  final candidates = roles.where((role) => role.game == game);
  return candidates
          .where((role) => role.accountId == dashboardRole?.accountId)
          .firstOrNull ??
      candidates.firstOrNull;
}

@Riverpod(keepAlive: true)
class CheckInCalendar extends _$CheckInCalendar {
  @override
  Future<CheckInMonth> build(String accountId, Game game) => ref
      .watch(checkInRepositoryProvider)
      .month(accountId: accountId, game: game);

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final repository = ref.read(checkInRepositoryProvider);
    state = await AsyncValue.guard(
      () => repository.month(accountId: accountId, game: game),
    );
  }

  Future<ClaimOutcome> claim() async {
    final outcome = await ref
        .read(checkInRepositoryProvider)
        .claim(accountId: accountId, game: game);
    if (outcome != ClaimOutcome.captcha) await refresh();
    return outcome;
  }
}

@Riverpod(keepAlive: true)
Stream<AutoCheckInSettings> autoCheckInSettings(Ref ref) =>
    ref.watch(checkInHistoryRepositoryProvider).watchSettings();

@Riverpod(keepAlive: true)
Stream<List<CheckInRun>> checkInRuns(Ref ref) =>
    ref.watch(checkInHistoryRepositoryProvider).watchRuns(limit: 10);

@Riverpod(keepAlive: true)
RunAutoCheckIn runAutoCheckIn(Ref ref) => RunAutoCheckIn(
  ref.watch(checkInRepositoryProvider),
  ref.watch(checkInHistoryRepositoryProvider),
  ref.watch(clockProvider),
);
