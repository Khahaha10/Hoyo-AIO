import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';

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
}
