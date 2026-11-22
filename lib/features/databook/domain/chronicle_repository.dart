import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';

const chroniclePrivateRetcode = 10102;

bool isChroniclePrivate(Object? error) =>
    error is ServerException && error.retcode == chroniclePrivateRetcode;

abstract interface class ChronicleRepository {
  Future<ChronicleResult<ChronicleSummary>> summary(
    SavedRole role, {
    bool refresh = false,
  });

  Future<ChronicleResult<List<ChronicleCharacter>>> characters(
    SavedRole role, {
    bool refresh = false,
  });

  Future<ChronicleResult<List<EndgameSummary>>> endgameOverview(
    SavedRole role, {
    bool refresh = false,
  });

  Future<ChronicleResult<List<EndgameSummary>>?> cachedEndgameOverview(
    SavedRole role,
  );

  Future<ChronicleResult<EndgameDetail>> endgameDetail(
    SavedRole role,
    EndgameMode mode, {
    required bool previous,
    bool refresh = false,
  });

  Future<ChronicleResult<CharacterDetail>> characterDetail(
    SavedRole role,
    int characterId, {
    bool refresh = false,
  });

  Future<void> makePublic(SavedRole role);
}
