import 'package:hoyo_aio/core/design_system/components/stamina_ring_card.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/onboarding/presentation/widgets/illustration_parts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class _MiniRing extends StatelessWidget {
  const _MiniRing({
    required this.fraction,
    required this.color,
    required this.size,
    this.label,
  });

  static const _strokeRatio = 0.12;

  final double fraction;
  final Color color;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: StaminaRingPainter(
        fraction: fraction,
        track: context.colors.surface3,
        fill: color,
        strokeWidth: size * _strokeRatio,
      ),
      child: label == null
          ? null
          : Center(
              child: Text(
                label!,
                style: AppTextStyles.tabular(AppTextStyles.titleL)
                    .copyWith(color: context.colors.text),
              ),
            ),
    ),
  );
}

class NotesIllustration extends StatelessWidget {
  const NotesIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FloatingChip(
              label: '${l10n.illustrationTrailblazePower} 168/240',
              dotColor: context.gameAccent(Game.starRail).acc,
            ),
          ),
          MiniCard(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.s16,
              children: [
                _MiniRing(
                  fraction: 0.71,
                  color: context.gameAccent(Game.genshin).acc,
                  size: 76,
                  label: '142',
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.illustrationResin,
                      style: AppTextStyles.label.copyWith(color: colors.text2),
                    ),
                    Text(
                      l10n.illustrationFullAt('21:40'),
                      style: AppTextStyles.tabular(AppTextStyles.rowTitle)
                          .copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.text,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FloatingChip(
              label: '${l10n.illustrationBattery} 186/240',
              dotColor: context.gameAccent(Game.zzz).acc,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FloatingChip(
              label: l10n.illustrationExpeditionComplete,
              icon: LucideIcons.compass,
              iconColor: colors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class WidgetsIllustration extends StatelessWidget {
  const WidgetsIllustration({super.key});

  static const double _width = 204;
  static const double _tile = 40;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Center(
      child: SizedBox(
        width: _width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.s12,
          children: [
            MiniCard(
              radius: AppRadius.widget,
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: Column(
                spacing: AppSpacing.s8,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.illustrationAllGames,
                          style: AppTextStyles.badge.copyWith(
                            color: colors.text,
                          ),
                        ),
                      ),
                      Text(
                        '18:28',
                        style: AppTextStyles.tabular(AppTextStyles.caption)
                            .copyWith(color: colors.text3),
                      ),
                    ],
                  ),
                  MiniBar(
                    fraction: 0.85,
                    color: context.gameAccent(Game.genshin).acc,
                  ),
                  MiniBar(
                    fraction: 0.82,
                    color: context.gameAccent(Game.starRail).acc,
                  ),
                  MiniBar(
                    fraction: 0.78,
                    color: context.gameAccent(Game.zzz).acc,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MiniCard(
                  radius: AppRadius.widget,
                  padding: const EdgeInsets.all(AppSpacing.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.s8,
                    children: [
                      _MiniRing(
                        fraction: 0.7,
                        color: context.gameAccent(Game.starRail).acc,
                        size: 32,
                      ),
                      Text(
                        '168/240',
                        style: AppTextStyles.tabular(AppTextStyles.label)
                            .copyWith(color: colors.text),
                      ),
                    ],
                  ),
                ),
                const Column(
                  spacing: AppSpacing.s12,
                  children: [
                    Row(
                      spacing: AppSpacing.s12,
                      children: [
                        PlaceholderTile(size: _tile),
                        PlaceholderTile(size: _tile),
                      ],
                    ),
                    Row(
                      spacing: AppSpacing.s12,
                      children: [
                        PlaceholderTile(size: _tile),
                        PlaceholderTile(size: _tile),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PlaceholderTile(size: _tile),
                PlaceholderTile(size: _tile),
                PlaceholderTile(size: _tile),
                PlaceholderTile(size: _tile),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CheckInIllustration extends StatelessWidget {
  const CheckInIllustration({super.key});

  static const double _cellSize = 44;
  static const _claimedCount = 5;
  static const _upcomingCount = 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cells = [
      for (var i = 0; i < _claimedCount; i++)
        _cell(context, colors.surface2, null, LucideIcons.check, colors.text2),
      _cell(context, BrandColors.lime, '×20', LucideIcons.gem, BrandColors.ink),
      for (var i = 0; i < _upcomingCount; i++)
        _cell(context, colors.surface, null, LucideIcons.gift, colors.text2),
    ];
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.s16,
        children: [
          MiniCard(
            padding: const EdgeInsets.all(AppSpacing.s12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.s8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.s8,
                  children: cells.sublist(0, 4),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.s8,
                  children: cells.sublist(4),
                ),
              ],
            ),
          ),
          FloatingChip(
            label: context.l10n.illustrationCheckedInGames(3),
            icon: LucideIcons.circleCheck,
            iconColor: colors.success,
          ),
        ],
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    Color background,
    String? quantity,
    IconData icon,
    Color foreground,
  ) => Container(
    width: _cellSize,
    height: _cellSize,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.iconTile),
      border: Border.all(color: context.colors.border),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppIcon(icon, size: AppIconSize.inline, color: foreground),
        if (quantity != null)
          Text(
            quantity,
            style: AppTextStyles.badge.copyWith(
              fontSize: 10,
              height: 12 / 10,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
      ],
    ),
  );
}
