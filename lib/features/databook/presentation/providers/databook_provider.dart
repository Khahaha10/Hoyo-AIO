import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/databook/data/chronicle_repository_impl.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_repository.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'databook_provider.g.dart';

class DatabookData {
  const DatabookData({this.summary, this.characters, this.endgame});

  final ChronicleResult<ChronicleSummary>? summary;
  final ChronicleResult<List<ChronicleCharacter>>? characters;
  final ChronicleResult<List<EndgameSummary>>? endgame;

  bool get isStale =>
      (summary?.isStale ?? false) ||
      (characters?.isStale ?? false) ||
      (endgame?.isStale ?? false);

  DateTime? get fetchedAt {
    final times = [
      ?summary?.fetchedAt,
      ?characters?.fetchedAt,
      ?endgame?.fetchedAt,
    ]..sort();
    return times.firstOrNull;
  }
}

typedef _Attempt<T> = ({T? result, Object? error});

Future<_Attempt<T>> _attempt<T>(Future<T> Function() load) async {
  try {
    return (result: await load(), error: null);
  } on Exception catch (error) {
    return (result: null, error: error);
  }
}

@Riverpod(keepAlive: true)
class Databook extends _$Databook {
  @override
  Future<DatabookData> build(SavedRole role) => _load(refresh: false);

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = const AsyncLoading<DatabookData>();
    state = await AsyncValue.guard(() => _load(refresh: true));
  }

  Future<DatabookData> _load({required bool refresh}) async {
    final repository = ref.read(chronicleRepositoryProvider);
    final (summary, characters, endgame) = await (
      _attempt(() => repository.summary(role, refresh: refresh)),
      _attempt(() => repository.characters(role, refresh: refresh)),
      _attempt(() => repository.endgameOverview(role, refresh: refresh)),
    ).wait;
    final errors = [?summary.error, ?characters.error, ?endgame.error];
    if (errors.length == 3) {
      throw errors.firstWhere(isChroniclePrivate, orElse: () => errors.first);
    }
    return DatabookData(
      summary: summary.result,
      characters: characters.result,
      endgame: endgame.result,
    );
  }

  Future<void> makePublic() async {
    await ref.read(chronicleRepositoryProvider).makePublic(role);
    state = const AsyncLoading<DatabookData>();
    state = await AsyncValue.guard(() => _load(refresh: true));
  }
}
