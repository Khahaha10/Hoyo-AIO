import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

const _noValue = '—';

extension DatabookFormat on AppLocalizations {
  String statLabel(ChronicleStatKind kind) => switch (kind) {
    ChronicleStatKind.activeDays => databookStatActiveDays,
    ChronicleStatKind.achievements => databookStatAchievements,
    ChronicleStatKind.characters => databookStatCharacters,
    ChronicleStatKind.chests => databookStatChests,
    ChronicleStatKind.waypoints => databookStatWaypoints,
    ChronicleStatKind.domains => databookStatDomains,
    ChronicleStatKind.agents => databookStatAgents,
    ChronicleStatKind.bangboo => databookStatBangboo,
  };

  String modeName(EndgameMode mode) => databookModeName(mode.name);

  String endgameSubtitle(EndgameSummary summary, DateTime now) {
    if (!summary.attempted) return databookNotAttempted;
    final left = summary.timeLeft(now);
    if (left != null) return databookResetsIn(duration(left));
    return databookCycleEnded;
  }

  String endgameValue(EndgameSummary summary) {
    if (!summary.attempted) return _noValue;
    return switch (summary.mode) {
      EndgameMode.imaginariumTheater => switch ((summary.act, summary.medals)) {
        (final act?, final medals?) => databookActMedals(act, medals),
        _ => _noValue,
      },
      EndgameMode.stygianOnslaught => switch (summary.difficulty) {
        final level? => databookDifficulty(level),
        null => _noValue,
      },
      EndgameMode.shiyuDefense => switch ((summary.rating, summary.score)) {
        (final rating?, _) => databookRating(rating),
        (_, final score?) when score > 0 => databookScoreValue(number(score)),
        _ => _noValue,
      },
      _ => _starsOrScore(summary),
    };
  }

  String _starsOrScore(EndgameSummary summary) => switch ((
    summary.stars,
    summary.maxStars,
    summary.score,
  )) {
    (final stars?, final max?, _) => databookStarsValue(stars, max),
    (final stars?, null, _) when stars > 0 => databookStarsOnly(stars),
    (_, _, final score?) when score > 0 => databookScoreValue(number(score)),
    _ => _noValue,
  };
}

IconData endgameIcon(EndgameMode mode) => switch (mode) {
  EndgameMode.spiralAbyss || EndgameMode.memoryOfChaos => LucideIcons.layers,
  EndgameMode.imaginariumTheater ||
  EndgameMode.pureFiction => LucideIcons.sparkles,
  EndgameMode.stygianOnslaught ||
  EndgameMode.apocalypticShadow ||
  EndgameMode.deadlyAssault => LucideIcons.skull,
  EndgameMode.anomalyArbitration => LucideIcons.target,
  EndgameMode.shiyuDefense => LucideIcons.shield,
};
