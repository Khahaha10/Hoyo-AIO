import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/design_system/components/reward_day_cell.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_month.dart';
import 'package:hoyo_aio/features/checkin/presentation/check_in_format.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../_support/pump_app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  test('rewardIcon matches known reward names case-insensitively', () {
    expect(rewardIcon('Primogem'), LucideIcons.gem);
    expect(rewardIcon('STELLAR JADE'), LucideIcons.gem);
    expect(rewardIcon('Mora'), LucideIcons.coins);
    expect(rewardIcon("Hero's Wit"), LucideIcons.bookOpen);
    expect(rewardIcon('Refined Ore'), LucideIcons.sparkles);
    expect(rewardIcon('Mystery Box'), LucideIcons.gift);
  });

  test('rewardDayState maps every status', () {
    expect(CheckInDayStatus.values.map(rewardDayState), RewardDayState.values);
  });

  test('rewardQuantity is compact from one thousand', () {
    expect(l10nEn.rewardQuantity(60), '×60');
    expect(l10nEn.rewardQuantity(5000), '5k');
  });

  test('rewardLabel joins name and quantity', () {
    expect(
      l10nEn.rewardLabel(
        const CheckInReward(day: 1, name: 'Primogem', count: 20),
      ),
      'Primogem ×20',
    );
  });

  test('date helpers format in the locale', () {
    final date = DateTime(2026, 11, 5);

    expect(l10nEn.checkInDate(date), 'Thu, 5 Nov');
    expect(l10nEn.checkInMonthTitle(date), 'November 2026');
  });
}
