import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';

enum RosterSort { level, rarity, constellation, friendship }

class RosterFilter {
  const RosterFilter({
    this.rarities = const {},
    this.chip,
    this.menu,
    this.query = '',
    this.sort = RosterSort.level,
  });

  final Set<int> rarities;
  final String? chip;
  final String? menu;
  final String query;
  final RosterSort sort;

  RosterFilter toggleRarity(int rarity) => RosterFilter(
    rarities: rarities.contains(rarity)
        ? ({...rarities}..remove(rarity))
        : {...rarities, rarity},
    chip: chip,
    menu: menu,
    query: query,
    sort: sort,
  );

  RosterFilter withChip(String? value) => RosterFilter(
    rarities: rarities,
    chip: chip == value ? null : value,
    menu: menu,
    query: query,
    sort: sort,
  );

  RosterFilter withMenu(String? value) => RosterFilter(
    rarities: rarities,
    chip: chip,
    menu: value,
    query: query,
    sort: sort,
  );

  RosterFilter withQuery(String value) => RosterFilter(
    rarities: rarities,
    chip: chip,
    menu: menu,
    query: value,
    sort: sort,
  );

  RosterFilter withSort(RosterSort value) => RosterFilter(
    rarities: rarities,
    chip: chip,
    menu: menu,
    query: query,
    sort: value,
  );
}

abstract final class RosterLogic {
  static const _genshinElements = [
    'pyro',
    'hydro',
    'anemo',
    'electro',
    'dendro',
    'cryo',
    'geo',
  ];
  static const _genshinWeapons = [
    'sword',
    'catalyst',
    'claymore',
    'bow',
    'polearm',
  ];
  static const _starRailPaths = [
    'destruction',
    'hunt',
    'erudition',
    'harmony',
    'nihility',
    'preservation',
    'abundance',
    'remembrance',
    'elation',
  ];
  static const _starRailElements = [
    'physical',
    'fire',
    'ice',
    'lightning',
    'wind',
    'quantum',
    'imaginary',
  ];
  static const _zzzElements = ['fire', 'ice', 'electric', 'ether', 'physical'];
  static const _zzzProfessions = [
    'attack',
    'stun',
    'anomaly',
    'support',
    'defense',
    'rupture',
  ];

  static String? chipOf(Game game, ChronicleCharacter c) =>
      game == Game.starRail ? c.kind : c.element;

  static String? menuOf(Game game, ChronicleCharacter c) =>
      game == Game.starRail ? c.element : c.kind;

  static List<String> chipValues(Game game, List<ChronicleCharacter> all) =>
      _present(
        switch (game) {
          Game.genshin => _genshinElements,
          Game.starRail => _starRailPaths,
          Game.zzz || Game.hi3 => _zzzElements,
        },
        {for (final c in all) ?chipOf(game, c)},
      );

  static List<String> menuValues(Game game, List<ChronicleCharacter> all) =>
      _present(
        switch (game) {
          Game.genshin => _genshinWeapons,
          Game.starRail => _starRailElements,
          Game.zzz || Game.hi3 => _zzzProfessions,
        },
        {for (final c in all) ?menuOf(game, c)},
      );

  static List<String> _present(List<String> order, Set<String> seen) => [
    for (final value in order)
      if (seen.contains(value)) value,
  ];

  static List<RosterSort> sortsFor(Game game) => [
    RosterSort.level,
    RosterSort.rarity,
    RosterSort.constellation,
    if (game == Game.genshin) RosterSort.friendship,
  ];

  static String sortId(Game game, RosterSort sort) => switch (sort) {
    RosterSort.level => 'level',
    RosterSort.rarity => 'rarity',
    RosterSort.friendship => 'friendship',
    RosterSort.constellation => switch (game) {
      Game.genshin => 'constellationGenshin',
      Game.starRail => 'constellationStarRail',
      Game.zzz || Game.hi3 => 'constellationZzz',
    },
  };

  static List<ChronicleCharacter> apply(
    Game game,
    List<ChronicleCharacter> all,
    RosterFilter filter,
  ) {
    final query = filter.query.trim().toLowerCase();
    final matches = [
      for (final c in all)
        if ((filter.rarities.isEmpty || filter.rarities.contains(c.rarity)) &&
            (filter.chip == null || chipOf(game, c) == filter.chip) &&
            (filter.menu == null || menuOf(game, c) == filter.menu) &&
            (query.isEmpty || c.name.toLowerCase().contains(query)))
          c,
    ];
    return matches..sort((a, b) => _compare(filter.sort, a, b));
  }

  static int _compare(
    RosterSort sort,
    ChronicleCharacter a,
    ChronicleCharacter b,
  ) {
    final primary = switch (sort) {
      RosterSort.level => b.level.compareTo(a.level),
      RosterSort.rarity => b.rarity.compareTo(a.rarity),
      RosterSort.constellation => b.constellation.compareTo(a.constellation),
      RosterSort.friendship => (b.friendship ?? 0).compareTo(a.friendship ?? 0),
    };
    if (primary != 0) return primary;
    final rarity = b.rarity.compareTo(a.rarity);
    if (rarity != 0) return rarity;
    final level = b.level.compareTo(a.level);
    if (level != 0) return level;
    return a.name.compareTo(b.name);
  }
}
