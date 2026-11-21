import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';

part 'gacha_record.freezed.dart';

@freezed
abstract class GachaRecord with _$GachaRecord {
  const factory GachaRecord({
    required Game game,
    required int id,
    required String uid,
    required String banner,
    required String name,
    required String itemType,
    required int rank,
    required String time,
  }) = _GachaRecord;
}

@freezed
abstract class FiveStarPull with _$FiveStarPull {
  const factory FiveStarPull({
    required GachaRecord record,
    required int pulls,
  }) = _FiveStarPull;
}

@freezed
abstract class BannerPity with _$BannerPity {
  const factory BannerPity({
    required String banner,
    required int total,
    required int pity5,
    required int pity4,
    required List<FiveStarPull> fiveStars,
  }) = _BannerPity;

  const BannerPity._();

  double? get averageFiveStar => fiveStars.isEmpty
      ? null
      : fiveStars.map((pull) => pull.pulls).reduce((a, b) => a + b) /
            fiveStars.length;

  static const _fiveStar = 5;
  static const _fourStar = 4;

  static BannerPity of(String banner, List<GachaRecord> records) {
    final ordered = [...records]..sort((a, b) => a.id.compareTo(b.id));
    var since5 = 0;
    var since4 = 0;
    final fiveStars = <FiveStarPull>[];
    for (final record in ordered) {
      since5++;
      since4++;
      if (record.rank >= _fiveStar) {
        fiveStars.add(FiveStarPull(record: record, pulls: since5));
        since5 = 0;
        since4 = 0;
      } else if (record.rank == _fourStar) {
        since4 = 0;
      }
    }
    return BannerPity(
      banner: banner,
      total: ordered.length,
      pity5: since5,
      pity4: since4,
      fiveStars: fiveStars.reversed.toList(),
    );
  }
}
