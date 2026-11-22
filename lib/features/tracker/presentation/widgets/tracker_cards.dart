import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_record.dart';
import 'package:hoyo_aio/features/tracker/presentation/tracker_labels.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

(int, int) pityLimits(Game game, String banner) =>
    HoyolabConfig.gachaPity['${game.name}.$banner'] ?? (90, 74);

class TrackerBar extends StatelessWidget {
  const TrackerBar({
    required this.value,
    required this.color,
    this.height = 6,
    super.key,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height / 2),
    child: LinearProgressIndicator(
      value: value.clamp(0, 1),
      minHeight: height,
      color: color,
      backgroundColor: context.colors.surface3,
    ),
  );
}

class PityHeroCard extends StatelessWidget {
  const PityHeroCard({
    required this.game,
    required this.banner,
    required this.pity,
    this.showFourStar = true,
    super.key,
  });

  static const double _barHeight = 10;
  static const double _tick = 2;
  static const double _tickHeight = 20;
  static const double _valueSize = 48;

  final Game game;
  final String banner;
  final BannerPity pity;
  final bool showFourStar;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final accent = context.gameAccent(game);
    final (hard, soft) = pityLimits(game, banner);
    final caption = AppTextStyles.tabular(AppTextStyles.caption)
        .copyWith(color: colors.text2);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(color: colors.border),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.soft, colors.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s8,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  l10n
                      .trackerPityTitle(l10n.trackerBanner(game, banner))
                      .toUpperCase(),
                  style: AppTextStyles.overline.copyWith(color: colors.text2),
                ),
              ),
              if (pity.guaranteed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                    vertical: AppSpacing.s4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: accent.acc),
                  ),
                  child: Text(
                    l10n.trackerGuaranteed,
                    style: AppTextStyles.label.copyWith(color: accent.accInk),
                  ),
                ),
            ],
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${pity.pity5}',
                  style: TextStyle(
                    fontSize: _valueSize,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
                TextSpan(
                  text: ' / $hard',
                  style: AppTextStyles.titleL.copyWith(color: colors.text2),
                ),
              ],
            ),
            style: AppTextStyles.tabular(AppTextStyles.bodyM),
          ),
          LayoutBuilder(
            builder: (context, constraints) => Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                TrackerBar(
                  value: pity.pity5 / hard,
                  color: accent.acc,
                  height: _barHeight,
                ),
                Positioned(
                  left: constraints.maxWidth * soft / hard,
                  child: Container(
                    width: _tick,
                    height: _tickHeight,
                    color: colors.text,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text('0', style: caption),
              const Spacer(),
              Text(
                l10n.trackerSoftPity(soft),
                style: caption.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Text('$hard', style: caption),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Row(
            spacing: AppSpacing.s12,
            children: [
              if (showFourStar)
                Expanded(
                  child: _FourStarCard(pity: pity, game: game),
                ),
              Expanded(
                child: _EstimateCard(
                  game: game,
                  toSoft: (soft - pity.pity5).clamp(0, hard),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FourStarCard extends StatelessWidget {
  const _FourStarCard({required this.pity, required this.game});

  static const _fourStarHard = 10;

  final BannerPity pity;
  final Game game;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s4,
        children: [
          Text(
            context.l10n.trackerFourStarPity,
            style: AppTextStyles.label.copyWith(color: colors.text2),
          ),
          Text(
            '${pity.pity4} / $_fourStarHard',
            style: AppTextStyles.tabular(AppTextStyles.titleM)
                .copyWith(color: colors.text),
          ),
          TrackerBar(
            value: pity.pity4 / _fourStarHard,
            color: context.gameAccent(game).acc,
          ),
        ],
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({required this.game, required this.toSoft});

  final Game game;
  final int toSoft;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final cost = HoyolabConfig.gachaPullCost[game] ?? 0;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s4,
        children: [
          Text(
            l10n.trackerToSoftPity,
            style: AppTextStyles.label.copyWith(color: colors.text2),
          ),
          Text(
            l10n.trackerPulls(game, toSoft),
            style: AppTextStyles.tabular(AppTextStyles.titleM)
                .copyWith(color: colors.text),
          ),
          Text(
            '${l10n.number(toSoft * cost)} ${l10n.trackerCurrency(game)}',
            style: AppTextStyles.tabular(AppTextStyles.caption)
                .copyWith(color: colors.text2),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            style: AppTextStyles.label.copyWith(color: colors.text2),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTextStyles.tabular(AppTextStyles.titleL)
                  .copyWith(color: colors.text),
            ),
          ),
        ],
      ),
    );
  }
}

class FiveStarRow extends StatelessWidget {
  const FiveStarRow({
    required this.pull,
    required this.game,
    required this.hard,
    super.key,
  });

  static const double _avatar = 36;

  final FiveStarPull pull;
  final Game game;
  final int hard;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final result = pull.fiftyFifty;
    final lost = result == FiftyFifty.lost;
    final name = pull.record.name;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      child: Row(
        spacing: AppSpacing.s12,
        children: [
          Container(
            width: _avatar,
            height: _avatar,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.warningBg,
              shape: BoxShape.circle,
            ),
            child: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: AppTextStyles.label.copyWith(color: colors.warning),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.s4,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.rowTitle.copyWith(
                          color: colors.text,
                        ),
                      ),
                    ),
                    if (result case final value?
                        when value != FiftyFifty.guaranteed)
                      AppBadge(
                        label: lost ? l10n.trackerLost : l10n.trackerWon,
                        variant: lost
                            ? AppBadgeVariant.danger
                            : AppBadgeVariant.success,
                      ),
                  ],
                ),
                Row(
                  spacing: AppSpacing.s12,
                  children: [
                    Expanded(
                      child: TrackerBar(
                        value: pull.pulls / hard,
                        color: lost
                            ? colors.warning
                            : context.gameAccent(game).acc,
                      ),
                    ),
                    Text(
                      '${pull.pulls}',
                      style: AppTextStyles.tabular(AppTextStyles.label)
                          .copyWith(color: colors.text),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GachaEmptyCard extends StatelessWidget {
  const GachaEmptyCard({required this.onImport, super.key});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s12,
        children: [
          Icon(LucideIcons.link, color: colors.text2),
          Text(
            l10n.trackerEmptyTitle,
            style: AppTextStyles.titleM.copyWith(color: colors.text),
          ),
          Text(
            l10n.trackerEmptyBody,
            style: AppTextStyles.bodyM.copyWith(color: colors.text2),
          ),
          AppButton(
            label: l10n.trackerImport,
            icon: LucideIcons.clipboardPaste,
            onPressed: onImport,
          ),
        ],
      ),
    );
  }
}
