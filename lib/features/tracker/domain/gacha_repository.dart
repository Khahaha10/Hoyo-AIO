import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_record.dart';

abstract interface class GachaRepository {
  Future<Game> importLink(String raw);

  Future<int> sync(Game game, {void Function(int fetched)? onProgress});

  Future<DateTime?> linkExpiresAt(Game game);

  Stream<List<GachaRecord>> watch(Game game);
}
