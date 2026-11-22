import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/chronicle_avatar.dart';

extension EndgameFormat on AppLocalizations {
  String statName(EndgameStatKind kind) => databookStatName(kind.name);

  String highlightName(EndgameHighlightKind kind) =>
      databookHighlightName(kind.name);

  String teamLabel(EndgameTeamLabel label) => databookTeamLabel(label.name);

  String rowTitle(EndgameRow row) {
    final title = row.title;
    if (title != null && title.isNotEmpty) return title;
    final index = row.index;
    if (index == null) return databookRowPlain(row.kind.name);
    return databookRowTitle(row.kind.name, index);
  }

  String sectionTitle(EndgameSection section) {
    final index = section.index;
    if (index == null && section.rows.length == 1) {
      return databookRowPlain(section.kind.name);
    }
    if (index == null) return databookRowPlural(section.kind.name);
    return databookRowTitle(section.kind.name, index);
  }

  String clock(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds % Duration.secondsPerMinute;
    if (minutes == 0) return databookSecondsShort(seconds);
    if (seconds == 0) return databookMinutesOnly(minutes);
    return databookMinutesSeconds(minutes, seconds);
  }

  String statValue(EndgameStat stat) {
    final text = stat.text;
    if (text != null) return text;
    final duration = stat.duration;
    if (duration != null) return clock(duration);
    return '${stat.number ?? 0}';
  }

  String? foldSummary(EndgameRowKind kind, List<EndgameRow> rows) {
    if (rows.isEmpty) return null;
    final ratings = {for (final row in rows) row.rating};
    if (ratings.length == 1 && ratings.first != null) {
      return databookAllRating(ratings.first!);
    }
    final graded = [
      for (final row in rows)
        if (row.stars != null && row.maxStars != null) row,
    ];
    if (graded.length != rows.length) return null;
    final stars = graded.fold<int>(0, (sum, row) => sum + row.stars!);
    final max = graded.fold<int>(0, (sum, row) => sum + row.maxStars!);
    if (kind == EndgameRowKind.act) return databookMedalCount(stars);
    return databookStarsValue(stars, max);
  }

  String rangeTitle(EndgameRowKind kind, List<EndgameRow> rows) {
    final label = databookRowPlural(kind.name);
    final indexes = [
      for (final row in rows)
        if (row.index != null) row.index!,
    ]..sort();
    if (indexes.isEmpty) return label;
    return databookRange(label, indexes.first, indexes.last);
  }
}

String? memberIcon(String? own, ChronicleCharacter? fallback) =>
    ChronicleAvatar.isAllowedImage(own) ? own : fallback?.iconUrl;
