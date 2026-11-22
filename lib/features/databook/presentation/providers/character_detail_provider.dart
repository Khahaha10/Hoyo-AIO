import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/databook/data/chronicle_repository_impl.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'character_detail_provider.g.dart';

@riverpod
Future<ChronicleResult<CharacterDetail>> characterDetail(
  Ref ref,
  SavedRole role,
  int characterId,
) => ref.watch(chronicleRepositoryProvider).characterDetail(role, characterId);
