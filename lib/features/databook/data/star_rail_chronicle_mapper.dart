import 'package:hoyo_aio/features/databook/data/json_view.dart';
import 'package:hoyo_aio/features/databook/data/server_time.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';

abstract final class StarRailChronicleMapper {
  static const _paths = {
    1: 'destruction',
    2: 'hunt',
    3: 'erudition',
    4: 'harmony',
    5: 'nihility',
    6: 'preservation',
    7: 'abundance',
    8: 'remembrance',
    9: 'elation',
  };
  static const _romans = {
    'I': 1,
    'II': 2,
    'III': 3,
    'IV': 4,
    'V': 5,
    'VI': 6,
    'VII': 7,
    'VIII': 8,
    'IX': 9,
    'X': 10,
    'XI': 11,
    'XII': 12,
  };
  static const _starsPerFloor = 3;
  static const _chaosMaxStars = 36;
  static const _fictionMaxStars = 12;
  static const _shadowMaxStars = 12;

  static final _romanInName = RegExp(r'\(([IVX]+)\)');
  static final _difficultyInName = RegExp(r'Difficulty\s*(\d+)');

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
          stats['achievement_num'].intValue,
        ),
        ChronicleStat(
          ChronicleStatKind.characters,
          stats['avatar_num'].intValue,
        ),
        ChronicleStat(ChronicleStatKind.chests, stats['chest_num'].intValue),
      ],
    );
  }

  static List<ChronicleCharacter> characters(Json data) => [
    for (final item in data['avatar_list'].items) ?_character(item),
  ];

  static ChronicleCharacter? _character(Json item) {
    final id = item['id'].intOrNull;
    final name = item['name'].stringOrNull;
    if (id == null || name == null) return null;
    final equip = item['equip'];
    final lightCone = equip['name'].stringOrNull;
    return ChronicleCharacter(
      id: id,
      name: name,
      level: item['level'].intValue,
      rarity: item['rarity'].intValue,
      element: item['element'].stringValue.toLowerCase(),
      kind: _paths[item['base_type'].intOrNull],
      constellation: item['rank'].intValue,
      iconUrl: item['icon'].stringOrNull,
      weapon: lightCone == null
          ? null
          : ChronicleWeapon(
              name: lightCone,
              level: equip['level'].intValue,
              rarity: equip['rarity'].intValue,
              refinement: equip['rank'].intOrNull,
              iconUrl: equip['icon'].stringOrNull,
            ),
    );
  }

  static CharacterDetail characterDetail(Json data, int characterId) {
    final avatar =
        data['avatar_list'].items
            .where((a) => a['id'].intOrNull == characterId)
            .firstOrNull ??
        const Json(null);
    return CharacterDetail(
      gear: [
        for (final piece in [
          ...avatar['relics'].items,
          ...avatar['ornaments'].items,
        ])
          if (piece['name'].stringOrNull case final name?)
            GearGroup(name: name, upgrade: piece['level'].intOrNull),
      ],
    );
  }

  static EndgameSummary endgameSummary(
    EndgameMode mode,
    Json data,
    Duration offset, {
    bool previous = false,
    DateTime? now,
  }) => switch (mode) {
    EndgameMode.memoryOfChaos => _floorsSummary(
      mode,
      data,
      offset,
      _chaosMaxStars,
    ),
    EndgameMode.pureFiction => _floorsSummary(
      mode,
      data,
      offset,
      _fictionMaxStars,
    ),
    EndgameMode.apocalypticShadow => _floorsSummary(
      mode,
      data,
      offset,
      _shadowMaxStars,
    ),
    EndgameMode.anomalyArbitration => _arbitrationSummary(
      _pickRecord(data, offset, now ?? DateTime.now(), previous: previous),
      offset,
    ),
    _ => throw ArgumentError.value(mode, 'mode', 'not a Star Rail mode'),
  };

  static EndgameDetail endgameDetail(
    EndgameMode mode,
    Json data,
    Duration offset, {
    required bool previous,
    required DateTime now,
  }) => switch (mode) {
    EndgameMode.anomalyArbitration => _arbitrationDetail(
      _pickRecord(data, offset, now, previous: previous),
      offset,
    ),
    _ => _floorsDetail(mode, data, offset),
  };

  static EndgameSummary _floorsSummary(
    EndgameMode mode,
    Json d,
    Duration offset,
    int maxStars,
  ) {
    final groups = d['groups'].items;
    final group = groups.isEmpty ? d : groups.first;
    return EndgameSummary(
      mode: mode,
      attempted: d['has_data'].boolValue && d['battle_num'].intValue > 0,
      startsAt: ServerTime.fromParts(
        d['begin_time'].isMap ? d['begin_time'] : group['begin_time'],
        offset,
      ),
      endsAt: ServerTime.fromParts(
        d['end_time'].isMap ? d['end_time'] : group['end_time'],
        offset,
      ),
      stars: d['star_num'].intValue,
      maxStars: maxStars,
    );
  }

  static EndgameDetail _floorsDetail(
    EndgameMode mode,
    Json d,
    Duration offset,
  ) {
    final floors = [
      for (final floor in d['all_floor_detail'].items) _floorRow(mode, floor),
    ]..sort((a, b) => (b.index ?? 0).compareTo(a.index ?? 0));
    final maxStars = switch (mode) {
      EndgameMode.memoryOfChaos => _chaosMaxStars,
      EndgameMode.pureFiction => _fictionMaxStars,
      _ => _shadowMaxStars,
    };
    return EndgameDetail(
      summary: _floorsSummary(mode, d, offset, maxStars),
      stats: [
        EndgameStat(EndgameStatKind.stars, number: d['star_num'].intValue),
        if (d['max_floor'].stringOrNull case final floor?)
          EndgameStat(EndgameStatKind.maxFloor, text: floor),
        EndgameStat(EndgameStatKind.battles, number: d['battle_num'].intValue),
      ],
      sections: [
        if (floors.isNotEmpty)
          EndgameSection(kind: EndgameRowKind.floor, rows: floors),
      ],
    );
  }

  static EndgameRow _floorRow(EndgameMode mode, Json floor) {
    final nodes = [
      (EndgameTeamLabel.node1, floor['node_1']),
      (EndgameTeamLabel.node2, floor['node_2']),
      (EndgameTeamLabel.node3, floor['node_3']),
    ];
    final score = nodes.fold<int>(
      0,
      (sum, node) => sum + node.$2['score'].intValue,
    );
    return EndgameRow(
      kind: EndgameRowKind.floor,
      index: _floorNumber(floor['name'].stringValue, floor['maze_id'].intValue),
      stars: switch (floor['star_num'].intOrNull) {
        final value? => value.clamp(0, _starsPerFloor),
        null => null,
      },
      maxStars: _starsPerFloor,
      rounds: _positive(floor['round_num'].intOrNull),
      score: score > 0 ? score : null,
      teams: [
        for (final (label, node) in nodes)
          if (node['avatars'].items.isNotEmpty)
            EndgameTeam(label, _members(node['avatars'])),
      ],
    );
  }

  static int? _positive(int? value) => (value ?? 0) > 0 ? value : null;

  static int? _floorNumber(String name, int mazeId) {
    final roman = _romanInName.firstMatch(name)?.group(1);
    if (roman != null && _romans[roman] != null) return _romans[roman];
    final difficulty = _difficultyInName.firstMatch(name)?.group(1);
    if (difficulty != null) return int.tryParse(difficulty);
    return mazeId > 0 ? mazeId % 100 : null;
  }

  static Json _pickRecord(
    Json data,
    Duration offset,
    DateTime now, {
    required bool previous,
  }) {
    final records = [...data['challenge_peak_records'].items]
      ..sort((a, b) => _begin(b, offset).compareTo(_begin(a, offset)));
    if (records.isEmpty) return const Json(null);
    final currentIndex = records.indexWhere((r) => _isRunning(r, offset, now));
    final index = currentIndex < 0 ? 0 : currentIndex;
    if (!previous) return records[index];
    return index + 1 < records.length ? records[index + 1] : const Json(null);
  }

  static DateTime _begin(Json record, Duration offset) =>
      ServerTime.fromParts(record['group']['begin_time'], offset) ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  static bool _isRunning(Json record, Duration offset, DateTime now) {
    final begin = ServerTime.fromParts(record['group']['begin_time'], offset);
    final end = ServerTime.fromParts(record['group']['end_time'], offset);
    return begin != null &&
        end != null &&
        !now.isBefore(begin) &&
        now.isBefore(end);
  }

  static EndgameSummary _arbitrationSummary(Json record, Duration offset) {
    final group = record['group'];
    final mobs = record['mob_records'].items;
    final stars =
        record['boss_record']['star_num'].intValue +
        mobs.fold<int>(0, (sum, mob) => sum + mob['star_num'].intValue);
    final nodes = record['mob_infos'].items.length + 1;
    return EndgameSummary(
      mode: EndgameMode.anomalyArbitration,
      attempted: record['has_challenge_record'].boolValue,
      startsAt: ServerTime.fromParts(group['begin_time'], offset),
      endsAt: ServerTime.fromParts(group['end_time'], offset),
      stars: stars,
      maxStars: nodes * _starsPerFloor,
    );
  }

  static EndgameDetail _arbitrationDetail(Json record, Duration offset) {
    final boss = record['boss_record'];
    final infos = record['mob_infos'].items;
    final rows = <EndgameRow>[
      if (boss['has_challenge_record'].boolValue)
        EndgameRow(
          kind: EndgameRowKind.boss,
          title: record['boss_info']['name_mi18n'].stringOrNull,
          stars: boss['star_num'].intOrNull,
          maxStars: _starsPerFloor,
          teams: [
            EndgameTeam(EndgameTeamLabel.squad, _members(boss['avatars'])),
          ],
        ),
      for (final (i, mob) in record['mob_records'].items.indexed)
        if (mob['has_challenge_record'].boolValue)
          EndgameRow(
            kind: EndgameRowKind.record,
            title: i < infos.length ? infos[i]['name'].stringOrNull : null,
            stars: mob['star_num'].intOrNull,
            maxStars: _starsPerFloor,
            teams: [
              EndgameTeam(EndgameTeamLabel.squad, _members(mob['avatars'])),
            ],
          ),
    ];
    return EndgameDetail(
      summary: _arbitrationSummary(record, offset),
      stats: [
        EndgameStat(
          EndgameStatKind.battles,
          number: record['battle_num'].intValue,
        ),
      ],
      sections: [
        if (rows.isNotEmpty)
          EndgameSection(kind: EndgameRowKind.boss, rows: rows),
      ],
    );
  }

  static List<TeamMember> _members(Json list) => [
    for (final avatar in list.items)
      if (avatar['id'].intOrNull case final id?)
        TeamMember(
          id: id,
          iconUrl: avatar['icon'].stringOrNull,
          level: avatar['level'].intOrNull,
          rarity: avatar['rarity'].intOrNull,
          element: avatar['element'].stringOrNull?.toLowerCase(),
        ),
  ];
}
