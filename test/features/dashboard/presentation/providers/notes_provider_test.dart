import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/provider_retry.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/selected_role_provider.dart';
import 'package:hoyo_aio/features/dashboard/data/notes_repository_impl.dart';
import 'package:hoyo_aio/features/dashboard/domain/note_result.dart';
import 'package:hoyo_aio/features/dashboard/presentation/providers/notes_provider.dart';

import '../../_support/dashboard_fakes.dart';

void main() {
  late FakeNotesRepository repository;
  late DateTime now;
  final genshin = fakeRole(Game.genshin);
  final starRail = fakeRole(Game.starRail);

  NoteResult resultAt(Game game, DateTime fetchedAt) =>
      NoteResult(note: fixtureNote(game, fetchedAt: fetchedAt));

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [
        notesRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => now),
        clockTickProvider.overrideWith((ref) => Stream.value(now)),
        accountsProvider.overrideWith(
          (ref) => Stream.value([
            fakeAccount(roles: [genshin, starRail]),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    repository = FakeNotesRepository();
    now = fixedNow;
  });

  group('notesProvider', () {
    test('refreshes from the network when nothing is cached', () async {
      repository.refreshResults[genshin.id] = resultAt(Game.genshin, now);
      final container = makeContainer();

      final result = await container.read(notesProvider(genshin).future);

      expect(result.note.fetchedAt, now);
      expect(repository.refreshed, [genshin]);
    });

    test('serves a fresh cache without refreshing', () async {
      repository.cachedResults[genshin.id] = resultAt(
        Game.genshin,
        now.subtract(const Duration(minutes: 4)),
      );
      final container = makeContainer();

      await container.read(notesProvider(genshin).future);
      await Future<void>.delayed(Duration.zero);

      expect(repository.refreshed, isEmpty);
    });

    test('serves an old cache first and then refreshes it', () async {
      final old = resultAt(Game.genshin, now.subtract(Notes.freshFor));
      final fresh = resultAt(Game.genshin, now);
      repository
        ..cachedResults[genshin.id] = old
        ..refreshResults[genshin.id] = fresh;
      final container = makeContainer();
      final states = <AsyncValue<NoteResult>>[];
      container.listen(
        notesProvider(genshin),
        (_, next) => states.add(next),
        fireImmediately: true,
      );

      final first = await container.read(notesProvider(genshin).future);
      expect(first, old);
      await Future<void>.delayed(Duration.zero);
      await container.read(notesProvider(genshin).future);

      expect(repository.refreshed, [genshin]);
      expect(container.read(notesProvider(genshin)).value, fresh);
      expect(states.any((state) => state.isLoading && state.hasValue), isTrue);
    });

    test('refresh surfaces an AppException as AsyncError', () async {
      repository
        ..cachedResults[genshin.id] = resultAt(Game.genshin, now)
        ..refreshErrors[genshin.id] = const NetworkException();
      final container = makeContainer();
      await container.read(notesProvider(genshin).future);

      await container.read(notesProvider(genshin).notifier).refresh();

      final state = container.read(notesProvider(genshin));
      expect(state.error, isA<NetworkException>());
      expect(state.value?.note.fetchedAt, now);
    });

    test('refresh is ignored while one is already running', () async {
      repository.cachedResults[genshin.id] = resultAt(Game.genshin, now);
      final container = makeContainer();
      await container.read(notesProvider(genshin).future);
      final notifier = container.read(notesProvider(genshin).notifier);

      await Future.wait([notifier.refresh(), notifier.refresh()]);

      expect(repository.refreshed, hasLength(1));
    });

    test('keeps per-game state when the selected game switches', () async {
      repository
        ..cachedResults[genshin.id] = resultAt(Game.genshin, now)
        ..cachedResults[starRail.id] = resultAt(Game.starRail, now);
      final container = makeContainer();
      container.listen(accountsProvider, (_, _) {});
      await container.read(accountsProvider.future);
      final gi = await container.read(notesProvider(genshin).future);

      container.read(selectedRoleIdProvider.notifier).selectGame(Game.starRail);
      expect(container.read(selectedRoleProvider), starRail);
      final hsr = await container.read(notesProvider(starRail).future);
      container.read(selectedRoleIdProvider.notifier).selectGame(Game.genshin);
      expect(container.read(selectedRoleProvider), genshin);

      expect(await container.read(notesProvider(genshin).future), same(gi));
      expect(hsr.note.game, Game.starRail);
      expect(repository.cachedCalls, [genshin, starRail]);
      expect(repository.refreshed, isEmpty);
    });
  });

  group('currentStaminaProvider', () {
    test('is null until notes load', () {
      repository.cachedResults[genshin.id] = resultAt(Game.genshin, now);
      final container = makeContainer();

      expect(container.read(currentStaminaProvider(genshin)), isNull);
    });

    test('ticks up locally without calling the network', () async {
      repository.cachedResults[genshin.id] = resultAt(Game.genshin, now);
      final container = makeContainer();
      container.listen(currentStaminaProvider(genshin), (_, _) {});
      await container.read(notesProvider(genshin).future);

      expect(container.read(currentStaminaProvider(genshin)), 142);

      now = now.add(const Duration(minutes: 3));
      container.invalidate(clockTickProvider);
      await container.read(clockTickProvider.future);

      final later = container.read(currentStaminaProvider(genshin));
      expect(later, greaterThan(142));
      expect(repository.refreshed, isEmpty);
    });
  });
}
