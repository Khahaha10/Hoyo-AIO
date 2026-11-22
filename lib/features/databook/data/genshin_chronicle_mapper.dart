import 'package:hoyo_aio/features/databook/data/json_view.dart';
import 'package:hoyo_aio/features/databook/data/server_time.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';

abstract final class GenshinChronicleMapper {
  static const _weaponKinds = {
    1: 'sword',
    10: 'catalyst',
    11: 'claymore',
    12: 'bow',
    13: 'polearm',
  };
  static const _abyssMaxStars = 36;

  static ChronicleSummary summary(Json data) {
    final stats = data['stats'];
    final chests =
        stats['common_chest_number'].intValue +
        stats['exquisite_chest_number'].intValue +
        stats['precious_chest_number'].intValue +
        stats['luxurious_chest_number'].intValue;
    return ChronicleSummary(
      stats: [
        ChronicleStat(
          ChronicleStatKind.activeDays,
          stats['active_day_number'].intValue,
        ),
        ChronicleStat(
          ChronicleStatKind.achievements,
          stats['achievement_number'].intValue,
        ),
        ChronicleStat(
          ChronicleStatKind.characters,
          stats['avatar_number'].intValue,
        ),
        ChronicleStat(ChronicleStatKind.chests, chests),
        ChronicleStat(
          ChronicleStatKind.waypoints,
          stats['way_point_number'].intValue,
        ),
        ChronicleStat(
          ChronicleStatKind.domains,
          stats['domain_number'].intValue,
        ),
      ],
      deepestAbyss: stats['spiral_abyss'].stringOrNull,
    );
  }

  static List<ChronicleCharacter> characters(Json data) => [
    for (final item in data['list'].items) ?_character(item),
  ];

  static ChronicleCharacter? _character(Json item) {
    final id = item['id'].intOrNull;
    final name = item['name'].stringOrNull;
    if (id == null || name == null) return null;
    return ChronicleCharacter(
      id: id,
      name: name,
      level: item['level'].intValue,
      rarity: item['rarity'].intValue,
      element: item['element'].stringValue.toLowerCase(),
      kind: _weaponKinds[item['weapon_type'].intOrNull],
      constellation: item['actived_constellation_num'].intValue,
      friendship: item['fetter'].intOrNull,
      iconUrl: item['icon'].stringOrNull,
      weapon: _weapon(item['weapon']),
    );
  }

  static ChronicleWeapon? _weapon(Json weapon) {
    final name = weapon['name'].stringOrNull;
    if (name == null) return null;
    return ChronicleWeapon(
      name: name,
      level: weapon['level'].intValue,
      rarity: weapon['rarity'].intValue,
      refinement: weapon['affix_level'].intOrNull,
      iconUrl: weapon['icon'].stringOrNull,
    );
  }

  static EndgameSummary endgameSummary(
    EndgameMode mode,
    Json data,
    DateTime now, {
    bool previous = false,
  }) => switch (mode) {
    EndgameMode.spiralAbyss => _abyssSummary(data),
    EndgameMode.imaginariumTheater => _theaterSummary(
      _pickRun(data['data'].items, now, previous: previous),
    ),
    EndgameMode.stygianOnslaught => _onslaughtSummary(
      _pickRun(data['data'].items, now, previous: previous),
    ),
    _ => throw ArgumentError.value(mode, 'mode', 'not a Genshin mode'),
  };

  static EndgameDetail endgameDetail(
    EndgameMode mode,
    Json data,
    DateTime now, {
    required bool previous,
  }) => switch (mode) {
    EndgameMode.spiralAbyss => _abyssDetail(data),
    EndgameMode.imaginariumTheater => _theaterDetail(
      _pickRun(data['data'].items, now, previous: previous),
    ),
    EndgameMode.stygianOnslaught => _onslaughtDetail(
      _pickRun(data['data'].items, now, previous: previous),
    ),
    _ => throw ArgumentError.value(mode, 'mode', 'not a Genshin mode'),
  };

  static Json _pickRun(
    List<Json> runs,
    DateTime now, {
    required bool previous,
  }) {
    if (runs.isEmpty) return const Json(null);
    final current =
        runs.where((run) => _contains(_schedule(run), now)).firstOrNull ??
        runs.first;
    if (!previous) return current;
    return runs.where((run) => run.raw != current.raw).firstOrNull ??
        const Json(null);
  }

  static Json _schedule(Json run) => run['schedule'];

  static bool _contains(Json schedule, DateTime now) {
    final start = ServerTime.fromEpochSeconds(schedule['start_time']);
    final end = ServerTime.fromEpochSeconds(schedule['end_time']);
    return start != null &&
        end != null &&
        !now.isBefore(start) &&
        now.isBefore(end);
  }

  static EndgameSummary _abyssSummary(Json d) => EndgameSummary(
    mode: EndgameMode.spiralAbyss,
    attempted: d['total_battle_times'].intValue > 0,
    startsAt: ServerTime.fromEpochSeconds(d['start_time']),
    endsAt: ServerTime.fromEpochSeconds(d['end_time']),
    stars: d['total_star'].intValue,
    maxStars: _abyssMaxStars,
  );

  static EndgameSummary _theaterSummary(Json run) {
    final stat = run['stat'];
    final schedule = _schedule(run);
    return EndgameSummary(
      mode: EndgameMode.imaginariumTheater,
      attempted: run['has_data'].boolValue,
      startsAt: ServerTime.fromEpochSeconds(schedule['start_time']),
      endsAt: ServerTime.fromEpochSeconds(schedule['end_time']),
      act: stat['max_round_id'].intOrNull,
      medals: stat['medal_num'].intOrNull,
      stars: stat['medal_num'].intOrNull,
      maxStars: stat['max_round_id'].intOrNull,
    );
  }

  static EndgameSummary _onslaughtSummary(Json run) {
    final schedule = _schedule(run);
    final best = run['single']['best'];
    final seconds = best['second'].intOrNull;
    return EndgameSummary(
      mode: EndgameMode.stygianOnslaught,
      attempted: run['single']['has_data'].boolValue,
      startsAt: ServerTime.fromEpochSeconds(schedule['start_time']),
      endsAt: ServerTime.fromEpochSeconds(schedule['end_time']),
      difficulty: best['difficulty'].intOrNull,
      time: seconds == null ? null : Duration(seconds: seconds),
    );
  }

  static EndgameDetail _abyssDetail(Json d) {
    final floors = [...d['floors'].items]
      ..sort((a, b) => b['index'].intValue.compareTo(a['index'].intValue));
    return EndgameDetail(
      summary: _abyssSummary(d),
      stats: [
        if (d['max_floor'].stringOrNull case final deepest?)
          EndgameStat(EndgameStatKind.deepest, text: deepest),
        EndgameStat(
          EndgameStatKind.battles,
          number: d['total_battle_times'].intValue,
        ),
        EndgameStat(
          EndgameStatKind.wins,
          number: d['total_win_times'].intValue,
        ),
      ],
      highlights: [
        for (final (kind, key) in _highlightKeys)
          ?_highlight(kind, d[key].items.firstOrNull),
      ],
      sections: [for (final floor in floors) _abyssFloor(floor)],
    );
  }

  static const _highlightKeys = [
    (EndgameHighlightKind.mostUsed, 'reveal_rank'),
    (EndgameHighlightKind.mostDefeats, 'defeat_rank'),
    (EndgameHighlightKind.strongestStrike, 'damage_rank'),
    (EndgameHighlightKind.mostDamageTaken, 'take_damage_rank'),
    (EndgameHighlightKind.burstsUnleashed, 'energy_skill_rank'),
    (EndgameHighlightKind.skillsCast, 'normal_skill_rank'),
  ];

  static EndgameHighlight? _highlight(EndgameHighlightKind kind, Json? entry) {
    final id = entry?['avatar_id'].intOrNull;
    if (entry == null || id == null) return null;
    return EndgameHighlight(
      kind: kind,
      avatarId: id,
      value: entry['value'].intValue,
      iconUrl: entry['avatar_icon'].stringOrNull,
    );
  }

  static EndgameSection _abyssFloor(Json floor) => EndgameSection(
    kind: EndgameRowKind.floor,
    index: floor['index'].intOrNull,
    stars: floor['star'].intOrNull,
    maxStars: floor['max_star'].intOrNull,
    rows: [
      for (final level in floor['levels'].items)
        EndgameRow(
          kind: EndgameRowKind.chamber,
          index: level['index'].intOrNull,
          stars: level['star'].intOrNull,
          maxStars: level['max_star'].intOrNull,
          teams: [
            for (final battle in level['battles'].items)
              EndgameTeam(
                battle['index'].intValue == 2
                    ? EndgameTeamLabel.second
                    : EndgameTeamLabel.first,
                _members(battle['avatars'], idKey: 'id'),
              ),
          ],
        ),
    ],
  );

  static EndgameDetail _theaterDetail(Json run) {
    final rounds = [
      ...run['detail']['rounds_data'].items,
    ]..sort((a, b) => b['round_id'].intValue.compareTo(a['round_id'].intValue));
    final stat = run['stat'];
    return EndgameDetail(
      summary: _theaterSummary(run),
      stats: [
        if (stat['max_round_id'].intOrNull case final act?)
          EndgameStat(EndgameStatKind.actReached, number: act),
        if (stat['medal_num'].intOrNull case final medals?)
          EndgameStat(EndgameStatKind.medals, number: medals),
      ],
      sections: [
        if (rounds.isNotEmpty)
          EndgameSection(
            kind: EndgameRowKind.act,
            rows: [
              for (final round in rounds)
                EndgameRow(
                  kind: EndgameRowKind.act,
                  index: round['round_id'].intOrNull,
                  stars: round['is_get_medal'].boolValue ? 1 : 0,
                  maxStars: 1,
                  teams: [
                    EndgameTeam(
                      EndgameTeamLabel.cast,
                      _members(round['avatars'], idKey: 'avatar_id'),
                    ),
                  ],
                ),
            ],
          ),
      ],
    );
  }

  static EndgameDetail _onslaughtDetail(Json run) {
    final best = run['single']['best'];
    final seconds = best['second'].intOrNull;
    return EndgameDetail(
      summary: _onslaughtSummary(run),
      stats: [
        if (best['difficulty'].intOrNull case final difficulty?)
          EndgameStat(EndgameStatKind.difficulty, number: difficulty),
        if (seconds != null)
          EndgameStat(
            EndgameStatKind.bestTime,
            duration: Duration(seconds: seconds),
          ),
      ],
      sections: [
        EndgameSection(
          kind: EndgameRowKind.challenge,
          rows: [
            for (final challenge in run['single']['challenge'].items)
              EndgameRow(
                kind: EndgameRowKind.challenge,
                title: challenge['name'].stringOrNull,
                time: switch (challenge['second'].intOrNull) {
                  final value? => Duration(seconds: value),
                  null => null,
                },
                teams: [
                  EndgameTeam(
                    EndgameTeamLabel.squad,
                    _members(challenge['teams'], idKey: 'avatar_id'),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  static List<TeamMember> _members(Json list, {required String idKey}) => [
    for (final avatar in list.items)
      if (avatar[idKey].intOrNull case final id?)
        TeamMember(
          id: id,
          name: avatar['name'].stringOrNull,
          iconUrl:
              avatar['icon'].stringOrNull ?? avatar['side_icon'].stringOrNull,
          level: avatar['level'].intOrNull,
          rarity: avatar['rarity'].intOrNull,
          element: avatar['element'].stringOrNull?.toLowerCase(),
        ),
  ];
}
