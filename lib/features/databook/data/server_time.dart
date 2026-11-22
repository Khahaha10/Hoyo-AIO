import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/game_region.dart';
import 'package:hoyo_aio/features/databook/data/json_view.dart';

abstract final class ServerTime {
  static const _asia = Duration(hours: 8);
  static const _america = Duration(hours: -5);
  static const _europe = Duration(hours: 1);

  static Duration offsetFor(Game game, String server) =>
      switch (regionFromServerId(game, server)) {
        GameRegion.america => _america,
        GameRegion.europe => _europe,
        GameRegion.asia || GameRegion.twHkMo || null => _asia,
      };

  static DateTime? fromParts(Json parts, Duration offset) {
    if (!parts.isMap) return null;
    final year = parts['year'].intOrNull;
    final month = parts['month'].intOrNull;
    final day = parts['day'].intOrNull;
    if (year == null || month == null || day == null || year == 0) return null;
    return DateTime.utc(
      year,
      month,
      day,
      parts['hour'].intValue,
      parts['minute'].intValue,
      parts['second'].intValue,
    ).subtract(offset);
  }

  static DateTime? fromEpochSeconds(Json seconds) {
    final value = seconds.intOrNull;
    if (value == null || value <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
  }
}
