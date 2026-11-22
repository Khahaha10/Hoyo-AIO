import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';
import 'package:hoyo_aio/features/databook/presentation/endgame_format.dart';
import 'package:material_ui/material_ui.dart';

class EndgameStatsCard extends StatelessWidget {
  const EndgameStatsCard({required this.detail, super.key});

  final EndgameDetail detail;

  @override
  Widget build(BuildContext context) {
    final stats = detail.stats;
    if (stats.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    final l10n = context.l10n;
    final accent = context.gameAccent(detail.summary.mode.game);
    final lead = stats.first;
    final max = lead.kind == EndgameStatKind.stars
        ? detail.summary.maxStars
        : null;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: DecoratedBox(
        decoration: const BoxDecoration(),
        child: Row(
          spacing: AppSpacing.s12,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.statName(lead.kind).toUpperCase(),
                    style: AppTextStyles.overline.copyWith(color: colors.text2),
                  ),
                  Text.rich(
                    TextSpan(
                      text: l10n.statValue(lead),
                      style: AppTextStyles.tabular(AppTextStyles.headline)
                          .copyWith(color: accent.accInk),
                      children: [
                        if (max != null)
                          TextSpan(
                            text: ' ${l10n.databookTotalOf(max)}',
                            style: AppTextStyles.tabular(AppTextStyles.label)
                                .copyWith(color: colors.text2),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            for (final stat in stats.skip(1).take(3))
              Expanded(
                child: Column(
                  children: [
                    Text(
                      l10n.statValue(stat),
                      style: AppTextStyles.tabular(AppTextStyles.titleM)
                          .copyWith(color: colors.text),
                    ),
                    Text(
                      l10n.statName(stat.kind),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.text2,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
