import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_record.dart';
import 'package:hoyo_aio/features/tracker/presentation/widgets/tracker_cards.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class PityBody extends StatelessWidget {
  const PityBody({
    required this.game,
    required this.banner,
    required this.pity,
    this.showFourStar = true,
    this.onOpenHistory,
    super.key,
  });

  static const _previewFiveStars = 3;
  static const _maxFiveStars = 12;

  final Game game;
  final String banner;
  final BannerPity pity;
  final bool showFourStar;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final (hard, _) = pityLimits(game, banner);
    final shown = pity.fiveStars
        .take(onOpenHistory == null ? _maxFiveStars : _previewFiveStars)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.cardGap,
      children: [
        PityHeroCard(
          game: game,
          banner: banner,
          pity: pity,
          showFourStar: showFourStar,
        ),
        Row(
          spacing: AppSpacing.s8,
          children: [
            Expanded(
              child: StatCard(
                label: l10n.trackerTotal,
                value: l10n.number(pity.total),
              ),
            ),
            Expanded(
              child: StatCard(
                label: l10n.trackerAverage,
                value: pity.averageFiveStar?.toStringAsFixed(1) ?? '–',
              ),
            ),
            Expanded(
              child: StatCard(
                label: l10n.trackerFiftyFifty,
                value: pity.fiftyFiftyTotal == 0
                    ? '–'
                    : l10n.trackerOf(pity.fiftyFiftyWon, pity.fiftyFiftyTotal),
              ),
            ),
          ],
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: onOpenHistory,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.trackerFiveStarHistory,
                          style: AppTextStyles.titleM.copyWith(
                            color: colors.text,
                          ),
                        ),
                      ),
                      Text(
                        l10n.trackerAll(pity.fiveStars.length),
                        style: AppTextStyles.label.copyWith(
                          color: colors.text2,
                        ),
                      ),
                      if (onOpenHistory != null)
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: colors.text2,
                        ),
                    ],
                  ),
                ),
              ),
              if (pity.fiveStars.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    0,
                    AppSpacing.s16,
                    AppSpacing.s16,
                  ),
                  child: Text(
                    l10n.trackerNoFiveStar,
                    style: AppTextStyles.bodyM.copyWith(color: colors.text2),
                  ),
                ),
              for (final (index, pull) in shown.indexed) ...[
                if (index > 0) Divider(height: 1, color: colors.border),
                FiveStarRow(pull: pull, game: game, hard: hard),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
