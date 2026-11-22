import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';
import 'package:hoyo_aio/features/databook/presentation/endgame_format.dart';
import 'package:material_ui/material_ui.dart';

class EndgameStatsCard extends StatelessWidget {
  const EndgameStatsCard({required this.detail, super.key});

  static const double _tintAlpha = 0.5;

  final EndgameDetail detail;

  String _value(AppLocalizations l10n, EndgameStat stat, bool isLead) {
    final max = detail.summary.maxStars;
    if (!isLead && stat.kind == EndgameStatKind.stars && max != null) {
      return '${stat.number ?? 0} / $max';
    }
    return l10n.statValue(stat);
  }

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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: colors.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.soft, colors.surface],
        ),
      ),
      child: Row(
        spacing: AppSpacing.s8,
        children: [
          Expanded(
            flex: 3,
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
                    style: AppTextStyles.tabular(AppTextStyles.display)
                        .copyWith(color: colors.text),
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
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.s8,
                  horizontal: AppSpacing.s4,
                ),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: _tintAlpha),
                  borderRadius: BorderRadius.circular(AppRadius.iconTile),
                ),
                child: Column(
                  children: [
                    Text(
                      _value(l10n, stat, false),
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
            ),
        ],
      ),
    );
  }
}
