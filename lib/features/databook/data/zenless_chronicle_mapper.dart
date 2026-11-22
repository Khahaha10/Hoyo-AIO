import 'package:hoyo_aio/features/databook/data/json_view.dart';
import 'package:hoyo_aio/features/databook/data/server_time.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';

abstract final class ZenlessChronicleMapper {
  static const _elements = {
    200: 'physical',
    201: 'fire',
    202: 'ice',
    203: 'electric',
    205: 'ether',
  };
  static const _professions = {
    1: 'attack',
    2: 'stun',
    3: 'anomaly',
    4: 'support',
    5: 'defense',
    6: 'rupture',
  };
  static const _starsPerBoss = 3;
  static const _sRank = 'S';

  static ChronicleSummary summary(Json data) {
    final stats = data['stats'];
    return ChronicleSummary(
      stats: [
        ChronicleStat(
          ChronicleStatKind.activeDays,
          stats['active_days'].intValue,
        ),
        ChronicleStat(
          ChronicleStatKind.achievements,
          stats['achievement_count'].intValue,
        ),
        ChronicleStat(ChronicleStatKind.agents, stats['avatar_num'].intValue),
        ChronicleStat(ChronicleStatKind.bangboo, stats['buddy_num'].intValue),
      ],
    );
  }

  static List<ChronicleCharacter> characters(Json data) => [
    for (final item in data['avatar_list'].items) ?_character(item),
  ];

  static ChronicleCharacter? _character(Json item) {
    final id = item['id'].intOrNull;
    final name = item['name_mi18n'].stringOrNull;
    if (id == null || name == null) return null;
    return ChronicleCharacter(
      id: id,
      name: name,
      level: item['level'].intValue,
      rarity: item['rarity'].stringValue == _sRank ? 5 : 4,
      element: _elements[item['element_type'].intOrNull] ?? 'unknown',
      kind: _professions[item['avatar_profession'].intOrNull],
      constellation: item['rank'].intValue,
      iconUrl: item['role_square_url'].stringOrNull,
    );
  }

  static CharacterDetail characterDetail(Json data) {
    final entry = data['avatar_list'].items.firstOrNull ?? const Json(null);
    final suits = <int, (String, int)>{};
    for (final disc in entry['equip'].items) {
      final suit = disc['equip_suit'];
      final id = suit['suit_id'].intOrNull;
      final name = suit['name'].stringOrNull;
      if (id == null || name == null) continue;
      final owned = suit['own'].intValue;
      final known = suits[id]?.$2 ?? 0;
      suits[id] = (name, owned > known ? owned : known);
    }
    final weapon = entry['weapon'];
    final weaponName = weapon['name'].stringOrNull;
    return CharacterDetail(
      weapon: weaponName == null
          ? null
          : ChronicleWeapon(
              name: weaponName,
              level: weapon['level'].intValue,
              rarity: _rarityNumber(weapon['rarity'].stringValue),
              refinement: weapon['star'].intOrNull,
              iconUrl: weapon['icon'].stringOrNull,
            ),
      gear: [
        for (final (name, pieces) in suits.values)
          GearGroup(name: name, pieces: pieces),
      ]..sort((a, b) => (b.pieces ?? 0).compareTo(a.pieces ?? 0)),
    );
  }

  static int _rarityNumber(String rank) => switch (rank) {
    'S' => 5,
    'A' => 4,
    _ => 3,
  };

  static EndgameSummary endgameSummary(
    EndgameMode mode,
    Json data,
    Duration offset,
  ) => switch (mode) {
    EndgameMode.shiyuDefense => _shiyuSummary(data, offset),
    EndgameMode.deadlyAssault => _assaultSummary(data, offset),
    _ => throw ArgumentError.value(mode, 'mode', 'not a ZZZ mode'),
  };

  static EndgameDetail endgameDetail(
    EndgameMode mode,
    Json data,
    Duration offset,
  ) {
    final summary = endgameSummary(mode, data, offset);
    return EndgameDetail(
      summary: summary,
      stats: [
        if (summary.rating case final rating?)
          EndgameStat(EndgameStatKind.rating, text: rating),
        if (summary.score case final score?)
          EndgameStat(EndgameStatKind.score, number: score),
        if (summary.stars case final stars?)
          EndgameStat(EndgameStatKind.stars, number: stars),
      ],
    );
  }

  static EndgameSummary _shiyuSummary(Json data, Duration offset) {
    final info = data['hadal_info_v2'];
    final brief = info['brief'];
    final rating = brief['rating'].stringOrNull;
    final score = brief['score'].intOrNull;
    return EndgameSummary(
      mode: EndgameMode.shiyuDefense,
      attempted: brief.isMap && (rating != null || (score ?? 0) > 0),
      startsAt:
          ServerTime.fromEpochSeconds(info['begin_time']) ??
          ServerTime.fromParts(info['hadal_begin_time'], offset),
      endsAt:
          ServerTime.fromEpochSeconds(info['end_time']) ??
          ServerTime.fromParts(info['hadal_end_time'], offset),
      rating: rating,
      score: score,
    );
  }

  static EndgameSummary _assaultSummary(Json data, Duration offset) {
    final bosses = data['list'].items.length;
    return EndgameSummary(
      mode: EndgameMode.deadlyAssault,
      attempted: data['has_data'].boolValue,
      startsAt: ServerTime.fromParts(data['start_time'], offset),
      endsAt: ServerTime.fromParts(data['end_time'], offset),
      stars: data['total_star'].intOrNull,
      maxStars: bosses > 0 ? bosses * _starsPerBoss : null,
      score: data['total_score'].intOrNull,
    );
  }
}
