import 'package:hoyo_aio/core/hoyolab/game.dart';

enum EndgameMode {
  spiralAbyss(Game.genshin),
  imaginariumTheater(Game.genshin),
  stygianOnslaught(Game.genshin),
  memoryOfChaos(Game.starRail),
  pureFiction(Game.starRail),
  apocalypticShadow(Game.starRail),
  anomalyArbitration(Game.starRail),
  shiyuDefense(Game.zzz),
  deadlyAssault(Game.zzz);

  const EndgameMode(this.game);

  final Game game;

  static List<EndgameMode> forGame(Game game) => [
    for (final mode in values)
      if (mode.game == game) mode,
  ];
}

class EndgameSummary {
  const EndgameSummary({
    required this.mode,
    required this.attempted,
    this.startsAt,
    this.endsAt,
    this.stars,
    this.maxStars,
    this.act,
    this.medals,
    this.rating,
    this.score,
    this.difficulty,
    this.time,
  });

  final EndgameMode mode;
  final bool attempted;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? stars;
  final int? maxStars;
  final int? act;
  final int? medals;
  final String? rating;
  final int? score;
  final int? difficulty;
  final Duration? time;

  double? get progress {
    final value = stars;
    final max = maxStars;
    if (value == null || max == null || max == 0) return null;
    return (value / max).clamp(0, 1).toDouble();
  }

  Duration? timeLeft(DateTime now) {
    final end = endsAt;
    if (end == null || !end.isAfter(now)) return null;
    return end.difference(now);
  }
}

enum EndgameStatKind {
  deepest,
  battles,
  wins,
  maxFloor,
  cycles,
  medals,
  actReached,
  battleTime,
  difficulty,
  bestTime,
  rating,
  score,
  stars,
  bosses,
}

class EndgameStat {
  const EndgameStat(this.kind, {this.number, this.text, this.duration});

  final EndgameStatKind kind;
  final int? number;
  final String? text;
  final Duration? duration;
}

enum EndgameHighlightKind {
  mostUsed,
  mostDefeats,
  strongestStrike,
  mostDamageTaken,
  skillsCast,
  burstsUnleashed,
}

class EndgameHighlight {
  const EndgameHighlight({
    required this.kind,
    required this.avatarId,
    required this.value,
    this.iconUrl,
  });

  final EndgameHighlightKind kind;
  final int avatarId;
  final int value;
  final String? iconUrl;
}

class TeamMember {
  const TeamMember({
    required this.id,
    this.name,
    this.iconUrl,
    this.level,
    this.rarity,
    this.element,
  });

  final int id;
  final String? name;
  final String? iconUrl;
  final int? level;
  final int? rarity;
  final String? element;
}

enum EndgameTeamLabel { first, second, node1, node2, node3, cast, squad }

class EndgameTeam {
  const EndgameTeam(this.label, this.members);

  final EndgameTeamLabel label;
  final List<TeamMember> members;
}

enum EndgameRowKind { chamber, act, floor, challenge, boss, frontier, record }

class EndgameRow {
  const EndgameRow({
    required this.kind,
    this.index,
    this.title,
    this.stars,
    this.maxStars,
    this.rating,
    this.score,
    this.rounds,
    this.time,
    this.teams = const [],
  });

  final EndgameRowKind kind;
  final int? index;
  final String? title;
  final int? stars;
  final int? maxStars;
  final String? rating;
  final int? score;
  final int? rounds;
  final Duration? time;
  final List<EndgameTeam> teams;
}

class EndgameSection {
  const EndgameSection({
    required this.kind,
    required this.rows,
    this.index,
    this.stars,
    this.maxStars,
  });

  final EndgameRowKind kind;
  final int? index;
  final int? stars;
  final int? maxStars;
  final List<EndgameRow> rows;
}

class EndgameDetail {
  const EndgameDetail({
    required this.summary,
    this.stats = const [],
    this.highlights = const [],
    this.sections = const [],
  });

  final EndgameSummary summary;
  final List<EndgameStat> stats;
  final List<EndgameHighlight> highlights;
  final List<EndgameSection> sections;
}
