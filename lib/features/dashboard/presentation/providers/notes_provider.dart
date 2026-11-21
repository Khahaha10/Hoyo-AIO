import 'dart:async';

import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/dashboard/data/notes_repository_impl.dart';
import 'package:hoyo_aio/features/dashboard/domain/note_result.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notes_provider.g.dart';

@Riverpod(keepAlive: true)
class Notes extends _$Notes {
  static const freshFor = Duration(minutes: 5);

  @override
  Future<NoteResult> build(SavedRole role) async {
    final repository = ref.watch(notesRepositoryProvider);
    final cached = await repository.cached(role);
    if (cached == null) return repository.refresh(role);
    final age = ref.read(clockProvider)().difference(cached.note.fetchedAt);
    if (age >= freshFor) Future<void>(refresh).ignore();
    return cached;
  }

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final repository = ref.read(notesRepositoryProvider);
    state = await AsyncValue.guard(() => repository.refresh(role));
  }
}

@riverpod
int? currentStamina(Ref ref, SavedRole role) {
  final now = ref.watch(clockTickProvider).value ?? ref.watch(clockProvider)();
  return ref.watch(notesProvider(role)).value?.note.stamina.currentAt(now);
}
