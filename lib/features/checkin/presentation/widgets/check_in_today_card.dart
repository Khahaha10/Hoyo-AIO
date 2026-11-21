import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_month.dart';
import 'package:hoyo_aio/features/checkin/presentation/check_in_format.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class CheckInTodayCard extends StatelessWidget {
  const CheckInTodayCard({
    required this.month,
    required this.isClaiming,
    required this.onClaim,
    this.autoRunAt,
    super.key,
  });

  static const double _tile = 52;

  final CheckInMonth month;
  final bool isClaiming;
  final VoidCallback? onClaim;
  final String? autoRunAt;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = context.gameAccent(month.game);
    final l10n = context.l10n;
    final reward = month.todayReward;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Row(
        spacing: AppSpacing.s16,
        children: [
          Container(
            width: _tile,
            height: _tile,
            decoration: BoxDecoration(
              color: accent.soft,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Center(
              child: AppIcon(
                reward == null ? LucideIcons.gift : rewardIcon(reward.name),
                color: accent.accInk,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.s4,
              children: [
                Text(
                  l10n.checkInTodayDay(month.todayIndex).toUpperCase(),
                  style: AppTextStyles.overline.copyWith(color: colors.text2),
                ),
                if (reward != null)
                  Text(
                    l10n.rewardLabel(reward),
                    style: AppTextStyles.tabular(AppTextStyles.titleM)
                        .copyWith(color: colors.text),
                  ),
                if (autoRunAt case final time? when !month.signedToday)
                  Text(
                    l10n.checkInAutoRunAt(time),
                    style: AppTextStyles.tabular(AppTextStyles.caption)
                        .copyWith(color: colors.text2),
                  ),
              ],
            ),
          ),
          if (month.signedToday)
            AppBadge(
              label: l10n.checkInDone,
              variant: AppBadgeVariant.success,
              icon: LucideIcons.check,
            )
          else
            AppButton(
              label: l10n.checkInNow,
              expand: false,
              size: AppButtonSize.medium,
              isLoading: isClaiming,
              onPressed: onClaim,
            ),
        ],
      ),
    );
  }
}
