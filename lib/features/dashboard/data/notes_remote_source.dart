import 'package:dio/dio.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';

class NotesRemoteSource {
  const NotesRemoteSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetch(SavedRole role) async {
    final (host, path, profile) = switch (role.game) {
      Game.genshin => (
        HoyolabConfig.gameRecordHost,
        HoyolabConfig.genshinNotePath,
        HeaderProfile.gameRecord,
      ),
      Game.starRail => (
        HoyolabConfig.gameRecordHost,
        HoyolabConfig.starRailNotePath,
        HeaderProfile.gameRecord,
      ),
      Game.zzz => (
        HoyolabConfig.zzzRecordHost,
        HoyolabConfig.zzzNotePath,
        HeaderProfile.zzzNotes,
      ),
      Game.hi3 => throw ArgumentError.value(role.game, 'game', 'has no notes'),
    };
    final response = await guardHoyolab(
      () => _dio.getUri<Map<String, dynamic>>(
        Uri.https(host, path, {'role_id': role.uid, 'server': role.server}),
        options: hoyolabOptions(
          accountId: role.accountId,
          profile: profile,
          game: role.game,
        ),
      ),
    );
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw const ParseException('notes: missing data');
    }
    return data;
  }
}
