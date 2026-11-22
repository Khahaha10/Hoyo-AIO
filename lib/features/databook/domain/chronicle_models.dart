enum ChronicleStatKind {
  activeDays,
  achievements,
  characters,
  chests,
  waypoints,
  domains,
  agents,
  bangboo,
}

class ChronicleStat {
  const ChronicleStat(this.kind, this.value);

  final ChronicleStatKind kind;
  final int value;
}

class ChronicleSummary {
  const ChronicleSummary({required this.stats, this.deepestAbyss});

  final List<ChronicleStat> stats;
  final String? deepestAbyss;
}

class ChronicleWeapon {
  const ChronicleWeapon({
    required this.name,
    required this.level,
    required this.rarity,
    this.refinement,
    this.iconUrl,
  });

  final String name;
  final int level;
  final int rarity;
  final int? refinement;
  final String? iconUrl;
}

class ChronicleCharacter {
  const ChronicleCharacter({
    required this.id,
    required this.name,
    required this.level,
    required this.rarity,
    required this.element,
    required this.constellation,
    this.kind,
    this.friendship,
    this.iconUrl,
    this.weapon,
  });

  final int id;
  final String name;
  final int level;
  final int rarity;
  final String element;
  final String? kind;
  final int constellation;
  final int? friendship;
  final String? iconUrl;
  final ChronicleWeapon? weapon;
}

class ChronicleResult<T> {
  const ChronicleResult({
    required this.data,
    required this.fetchedAt,
    this.isStale = false,
  });

  final T data;
  final DateTime fetchedAt;
  final bool isStale;
}
