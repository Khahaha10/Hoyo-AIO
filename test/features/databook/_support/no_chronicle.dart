import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_repository.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';

class NoChronicle implements ChronicleRepository {
  const NoChronicle();

  @override
  Future<ChronicleResult<List<EndgameSummary>>?> cachedEndgameOverview(
    SavedRole role,
  ) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
