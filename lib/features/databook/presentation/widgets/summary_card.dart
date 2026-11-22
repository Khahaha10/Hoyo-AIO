import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/presentation/databook_format.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({required this.summary, super.key});

  static const double _cardPadding = 12;
  static const double _cellGap = 8;
  static const int _wideColumns = 3;
  static const int _narrowColumns = 2;
  static const int _narrowStatCount = 4;

  final ChronicleSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final columns = summary.stats.length == _narrowStatCount
        ? _narrowColumns
        : _wideColumns;
    final deepest = summary.deepestAbyss;
    return AppCard(
      padding: const EdgeInsets.all(_cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.s12,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width =
                  (constraints.maxWidth - _cellGap * (columns - 1)) / columns;
              return Wrap(
                spacing: _cellGap,
                runSpacing: _cellGap,
                children: [
                  for (final stat in summary.stats)
                    SizedBox(
                      width: width,
                      child: _StatCell(
                        value: l10n.number(stat.value),
                        label: l10n.statLabel(stat.kind),
                      ),
                    ),
                ],
              );
            },
          ),
          if (deepest != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              child: Row(
                spacing: AppSpacing.s8,
                children: [
                  AppIcon(
                    LucideIcons.layers,
                    size: AppIconSize.inline,
                    color: colors.text2,
                  ),
                  Expanded(
                    child: Text(
                      l10n.databookSpiralDeepest,
                      style: AppTextStyles.bodyM.copyWith(color: colors.text2),
                    ),
                  ),
                  Text(
                    deepest,
                    style: AppTextStyles.tabular(AppTextStyles.rowTitle)
                        .copyWith(color: colors.text),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTextStyles.tabular(AppTextStyles.titleM)
                  .copyWith(color: colors.text),
            ),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: colors.text2,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
