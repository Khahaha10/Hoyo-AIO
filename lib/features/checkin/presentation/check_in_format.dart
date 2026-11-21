import 'package:hoyo_aio/core/design_system/components/reward_day_cell.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_month.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

const _rewardIcons = <String, IconData>{
  'primogem': LucideIcons.gem,
  'stellar jade': LucideIcons.gem,
  'polychrome': LucideIcons.gem,
  'crystal': LucideIcons.gem,
  'mora': LucideIcons.coins,
  'credit': LucideIcons.coins,
  'denny': LucideIcons.coins,
  'coin': LucideIcons.coins,
  'wit': LucideIcons.bookOpen,
  'experience': LucideIcons.bookOpen,
  'exp': LucideIcons.bookOpen,
  'record': LucideIcons.bookOpen,
  'ore': LucideIcons.sparkles,
  'lost gold': LucideIcons.sparkles,
  'w-engine': LucideIcons.sparkles,
  'material': LucideIcons.sparkles,
};

IconData rewardIcon(String name) {
  final lower = name.toLowerCase();
  for (final MapEntry(:key, :value) in _rewardIcons.entries) {
    if (lower.contains(key)) return value;
  }
  return LucideIcons.gift;
}

RewardDayState rewardDayState(CheckInDayStatus status) => switch (status) {
  CheckInDayStatus.claimed => RewardDayState.claimed,
  CheckInDayStatus.today => RewardDayState.today,
  CheckInDayStatus.missed => RewardDayState.missed,
  CheckInDayStatus.upcoming => RewardDayState.upcoming,
};

extension CheckInFormat on AppLocalizations {
  static const _compactFrom = 1000;

  String rewardQuantity(int count) => count >= _compactFrom
      ? NumberFormat.compact(locale: localeName).format(count).toLowerCase()
      : checkInQuantity(count);

  String rewardLabel(CheckInReward reward) =>
      checkInRewardLabel(reward.name, checkInQuantity(reward.count));

  String checkInDate(DateTime date) =>
      DateFormat('EEE, d MMM', localeName).format(date);

  String checkInMonthTitle(DateTime date) =>
      DateFormat.yMMMM(localeName).format(date);
}
