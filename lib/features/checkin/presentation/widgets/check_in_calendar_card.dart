import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/components/reward_day_cell.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_month.dart';
import 'package:hoyo_aio/features/checkin/presentation/check_in_format.dart';
import 'package:material_ui/material_ui.dart';

class CheckInCalendarCard extends StatelessWidget {
  const CheckInCalendarCard({required this.month, super.key});

  static const int _columns = 6;
  static const double _cellGap = 10;

  final CheckInMonth month;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final date = month.date;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.s16,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (date != null)
                      Text(
                        l10n.checkInMonthTitle(date),
                        style: AppTextStyles.titleM.copyWith(
                          color: colors.text,
                        ),
                      ),
                    Text(
                      l10n.checkInMonthSummary(
                        month.signedDays,
                        month.unreachableDays,
                      ),
                      style: AppTextStyles.tabular(AppTextStyles.caption)
                          .copyWith(color: colors.text2),
                    ),
                  ],
                ),
              ),
              const _Legend(),
            ],
          ),
          GridView(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _columns,
              mainAxisSpacing: _cellGap,
              crossAxisSpacing: _cellGap,
              mainAxisExtent: RewardDayCell.height,
            ),
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [for (final reward in month.rewards) _cell(l10n, reward)],
          ),
        ],
      ),
    );
  }

  Widget _cell(AppLocalizations l10n, CheckInReward reward) {
    final status = month.statusOf(reward.day);
    return RewardDayCell(
      key: ValueKey(reward.day),
      day: reward.day,
      icon: rewardIcon(reward.name),
      quantity: l10n.rewardQuantity(reward.count),
      state: rewardDayState(status),
      missedLabel: l10n.checkInMissed,
      semanticLabel: l10n.checkInDaySemantics(
        reward.day,
        l10n.rewardLabel(reward),
        switch (status) {
          CheckInDayStatus.claimed => l10n.checkInStatusClaimed,
          CheckInDayStatus.today => l10n.checkInStatusToday,
          CheckInDayStatus.missed => l10n.checkInStatusMissed,
          CheckInDayStatus.upcoming => l10n.checkInStatusUpcoming,
        },
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  static const double _swatch = 10;
  static const double _radius = 3;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final style = AppTextStyles.caption.copyWith(color: colors.text2);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.s4,
      children: [
        Container(
          width: _swatch,
          height: _swatch,
          decoration: BoxDecoration(
            color: BrandColors.lime,
            borderRadius: BorderRadius.circular(_radius),
          ),
        ),
        Text(l10n.checkInLegendToday, style: style),
        const SizedBox(width: AppSpacing.s4),
        Container(
          width: _swatch,
          height: _swatch,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: colors.border2),
          ),
        ),
        Text(l10n.checkInMissed, style: style),
      ],
    );
  }
}
