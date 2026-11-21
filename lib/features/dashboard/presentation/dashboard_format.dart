import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

extension DashboardFormat on AppLocalizations {
  String duration(Duration value) {
    final minutes = (value.inSeconds / Duration.secondsPerMinute).ceil();
    final days = minutes ~/ Duration.minutesPerDay;
    final hours = minutes % Duration.minutesPerDay ~/ Duration.minutesPerHour;
    final rest = minutes % Duration.minutesPerHour;
    if (days > 0) return durationDaysHours(days, hours);
    if (hours > 0) return durationHoursMinutes(hours, rest);
    return durationMinutes(rest < 1 ? 1 : rest);
  }

  String clockTime(DateTime value) =>
      DateFormat.Hm(localeName).format(value.toLocal());

  String number(int value) =>
      NumberFormat.decimalPattern(localeName).format(value);

  String atTime(DateTime at, DateTime now) {
    final local = at.toLocal();
    final today = DateUtils.dateOnly(now.toLocal());
    final day = DateUtils.dateOnly(local);
    final daysAhead = day.difference(today).inDays;
    if (daysAhead == 0) return dashboardAtToday(clockTime(local));
    if (daysAhead == 1) return dashboardAtTomorrow(clockTime(local));
    return dashboardAtDate(DateFormat.MMMd(localeName).add_Hm().format(local));
  }

  String lastUpdated(DateTime fetchedAt, DateTime now) {
    final age = now.difference(fetchedAt);
    if (age.inMinutes < 1) return dashboardUpdatedJustNow;
    if (age.inHours < 1) return dashboardUpdatedMinutes(age.inMinutes);
    if (age.inDays < 1) return dashboardUpdatedHours(age.inHours);
    return dashboardUpdatedAt(
      DateFormat.MMMd(localeName).add_Hm().format(fetchedAt.toLocal()),
    );
  }
}
