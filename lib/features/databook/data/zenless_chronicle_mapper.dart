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
    return switch (mode) {
      EndgameMode.shiyuDefense => _shiyuDetail(summary, data),
      _ => _assaultDetail(summary, data),
    };
  }

  static EndgameDetail _shiyuDetail(EndgameSummary summary, Json data) {
    final info = data['hadal_info_v2'];
    final rows = [
      for (final key in _shiyuLayerKeys)
        for (final layer in info[key]['layer_item_list'].items)
          _frontierRow(layer),
    ]..sort((a, b) => (b.index ?? 0).compareTo(a.index ?? 0));
    final times = [for (final row in rows) ?row.time]..sort();
    return EndgameDetail(
      summary: summary,
      stats: [
        if (summary.rating case final rating?)
          EndgameStat(EndgameStatKind.rating, text: rating),
        if (rows.isNotEmpty)
          EndgameStat(EndgameStatKind.frontiers, number: rows.length),
        if (rows.isNotEmpty)
          EndgameStat(
            EndgameStatKind.cleared,
            number: rows.where((row) => row.rating != null).length,
          ),
        if (times.isNotEmpty)
          EndgameStat(EndgameStatKind.bestTime, duration: times.first),
      ],
      sections: [
        if (rows.isNotEmpty)
          EndgameSection(kind: EndgameRowKind.frontier, rows: rows),
      ],
    );
  }

  static const _shiyuLayerKeys = ['fitfh_layer_detail', 'fourth_layer_detail'];
  static const _layerIdBase = 100;

  static EndgameRow _frontierRow(Json layer) {
    final id = layer['layer_id'].intOrNull;
    final seconds =
        layer['battle_time'].intOrNull ?? layer['challenge_time'].intOrNull;
    final nodes = [
      (EndgameTeamLabel.node1, layer['node_1']),
      (EndgameTeamLabel.node2, layer['node_2']),
    ];
    final nodeTeams = [
      for (final (label, node) in nodes)
        if (_members(node['avatars']).isNotEmpty)
          EndgameTeam(label, _members(node['avatars'])),
    ];
    final flat = _members(layer['avatar_list']);
    return EndgameRow(
      kind: EndgameRowKind.frontier,
      index: id == null
          ? null
          : (id % _layerIdBase == 0 ? id : id % _layerIdBase),
      rating: layer['rating'].stringOrNull,
      time: seconds != null && seconds > 0 ? Duration(seconds: seconds) : null,
      teams: nodeTeams.isNotEmpty
          ? nodeTeams
          : [if (flat.isNotEmpty) EndgameTeam(EndgameTeamLabel.squad, flat)],
    );
  }

  static EndgameDetail _assaultDetail(EndgameSummary summary, Json data) {
    final rows = [
      for (final key in ['list', 'hard_list'])
        for (final entry in data[key].items) _bossRow(entry),
    ];
    final best = rows.fold<int>(0, (top, row) {
      final score = row.score ?? 0;
      return score > top ? score : top;
    });
    return EndgameDetail(
      summary: summary,
      stats: [
        if (summary.score case final score?)
          EndgameStat(EndgameStatKind.score, number: score),
        if (summary.stars case final stars?)
          EndgameStat(EndgameStatKind.stars, number: stars),
        if (rows.isNotEmpty)
          EndgameStat(EndgameStatKind.bosses, number: rows.length),
        if (best > 0) EndgameStat(EndgameStatKind.bestScore, number: best),
      ],
      sections: [
        if (rows.isNotEmpty)
          EndgameSection(kind: EndgameRowKind.boss, rows: rows),
      ],
    );
  }

  static EndgameRow _bossRow(Json entry) {
    final boss = entry['boss'];
    final name =
        boss.items.firstOrNull?['name'].stringOrNull ??
        boss['name'].stringOrNull ??
        entry['name'].stringOrNull;
    final avatars = _members(entry['avatar_list']);
    final squad = avatars.isNotEmpty ? avatars : _members(entry['avatars']);
    final score = entry['score'].intOrNull;
    return EndgameRow(
      kind: EndgameRowKind.boss,
      title: name,
      stars: entry['star'].intOrNull,
      maxStars: _starsPerBoss,
      score: score != null && score > 0 ? score : null,
      teams: [if (squad.isNotEmpty) EndgameTeam(EndgameTeamLabel.squad, squad)],
    );
  }

  static List<TeamMember> _members(Json list) => [
    for (final avatar in list.items)
      if ((avatar['id'].intOrNull ?? avatar['avatar_id'].intOrNull)
          case final id?)
        TeamMember(
          id: id,
          iconUrl:
              avatar['role_square_url'].stringOrNull ??
              avatar['icon'].stringOrNull,
          level: avatar['level'].intOrNull,
          rarity: switch (avatar['rarity'].stringOrNull) {
            'S' => 5,
            'A' => 4,
            _ => null,
          },
          element: _elements[avatar['element_type'].intOrNull],
        ),
  ];

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
