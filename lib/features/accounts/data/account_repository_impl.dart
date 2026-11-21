import 'package:dio/dio.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/game_region.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio_provider.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';
import 'package:hoyo_aio/features/accounts/data/dto/record_card_dto.dart';
import 'package:hoyo_aio/features/accounts/domain/account_repository.dart';
import 'package:hoyo_aio/features/accounts/domain/detected_role.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_repository_impl.g.dart';

class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<DetectedRole>> detectRoles({
    required String accountId,
    required String hoyolabUid,
  }) async {
    final response = await guardHoyolab(
      () => _dio.getUri<Map<String, dynamic>>(
        Uri.https(HoyolabConfig.gameRecordHost, HoyolabConfig.recordCardPath, {
          'uid': hoyolabUid,
        }),
        options: hoyolabOptions(
          accountId: accountId,
          profile: HeaderProfile.gameRecord,
        ),
      ),
    );
    return _parseRoles(response.data);
  }

  static List<DetectedRole> _parseRoles(Map<String, dynamic>? body) {
    final data = body?['data'];
    final list = data is Map<String, dynamic> ? data['list'] : null;
    if (list is! List) return const [];
    try {
      return [
        for (final card in list.whereType<Map<String, dynamic>>())
          ?_toRole(RecordCardDto.fromJson(card)),
      ];
    } on CheckedFromJsonException catch (e) {
      throw ParseException('record card: ${e.key}');
    }
  }

  static DetectedRole? _toRole(RecordCardDto dto) {
    final game = gameFromHoyolabId(dto.gameId);
    if (game == null || !dto.hasRole || dto.gameRoleId.isEmpty) return null;
    return DetectedRole(
      game: game,
      uid: dto.gameRoleId,
      server: dto.region,
      region: regionFromServerId(game, dto.region),
      nickname: dto.nickname,
      level: dto.level,
    );
  }
}

@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) =>
    AccountRepositoryImpl(ref.watch(hoyolabDioProvider));
