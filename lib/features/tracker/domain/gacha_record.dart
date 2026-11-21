import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';

part 'gacha_record.freezed.dart';

enum FiftyFifty { won, lost, guaranteed }

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
    FiftyFifty? fiftyFifty,
  }) = _FiveStarPull;
}

@freezed
abstract class BannerPity with _$BannerPity {
  const factory BannerPity({
    required String banner,
    required int total,
    required int pity5,
    required int pity4,
    required bool guaranteed,
    required List<FiveStarPull> fiveStars,
    required Map<int, int> rowPity,
  }) = _BannerPity;

  const BannerPity._();

  static const fiveStar = 5;
  static const fourStar = 4;

  double? get averageFiveStar => fiveStars.isEmpty
      ? null
      : fiveStars.map((pull) => pull.pulls).reduce((a, b) => a + b) /
            fiveStars.length;

  int get fiftyFiftyWon =>
      fiveStars.where((pull) => pull.fiftyFifty == FiftyFifty.won).length;

  int get fiftyFiftyTotal => fiveStars
      .where(
        (pull) =>
            pull.fiftyFifty == FiftyFifty.won ||
            pull.fiftyFifty == FiftyFifty.lost,
      )
      .length;

  FiveStarPull? fiveStarFor(int recordId) =>
      fiveStars.where((pull) => pull.record.id == recordId).firstOrNull;

  static BannerPity of(
    String banner,
    List<GachaRecord> records, {
    Set<String>? standardPool,
  }) {
    final ordered = [...records]..sort((a, b) => a.id.compareTo(b.id));
    var since5 = 0;
    var since4 = 0;
    var guaranteed = false;
    final fiveStars = <FiveStarPull>[];
    final rowPity = <int, int>{};
    for (final record in ordered) {
      since5++;
      since4++;
      if (record.rank >= fiveStar) {
        final result = switch (standardPool) {
          null => null,
          _ when guaranteed => FiftyFifty.guaranteed,
          final pool when pool.contains(record.name) => FiftyFifty.lost,
          _ => FiftyFifty.won,
        };
        if (standardPool != null) guaranteed = result == FiftyFifty.lost;
        fiveStars.add(
          FiveStarPull(record: record, pulls: since5, fiftyFifty: result),
        );
        rowPity[record.id] = since5;
        since5 = 0;
        since4 = 0;
      } else if (record.rank == fourStar) {
        rowPity[record.id] = since4;
        since4 = 0;
      }
    }
    return BannerPity(
      banner: banner,
      total: ordered.length,
      pity5: since5,
      pity4: since4,
      guaranteed: guaranteed,
      fiveStars: fiveStars.reversed.toList(),
      rowPity: rowPity,
    );
  }
}
