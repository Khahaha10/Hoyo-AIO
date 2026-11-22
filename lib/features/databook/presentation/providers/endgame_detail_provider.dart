import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/databook/data/chronicle_repository_impl.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'endgame_detail_provider.g.dart';

@riverpod
Future<ChronicleResult<EndgameDetail>> endgameDetail(
  Ref ref,
  SavedRole role,
  EndgameMode mode,
  bool previous,
) => ref
    .watch(chronicleRepositoryProvider)
    .endgameDetail(role, mode, previous: previous);
