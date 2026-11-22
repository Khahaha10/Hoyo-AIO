import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';
import 'package:hoyo_aio/features/databook/presentation/endgame_format.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/endgame_fold.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/endgame_row_tile.dart';
import 'package:material_ui/material_ui.dart';

class EndgameSectionCard extends StatelessWidget {
  const EndgameSectionCard({
    required this.section,
    required this.roster,
    this.visibleRows = 3,
    super.key,
  });

  static const double _headerHeight = 52;

  final EndgameSection section;
  final Map<int, ChronicleCharacter> roster;
  final int visibleRows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final rows = section.rows;
    final shown = rows.take(visibleRows).toList();
    final hidden = rows.skip(visibleRows).toList();
    final stars = section.stars;
    final maxStars = section.maxStars;
    final summary = stars != null && maxStars != null
        ? l10n.databookStarsValue(stars, maxStars)
        : l10n.foldSummary(section.kind, rows);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _headerHeight,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.sectionTitle(section),
                    style: AppTextStyles.titleM.copyWith(color: colors.text),
                  ),
                ),
                if (summary != null)
                  Text(
                    summary,
                    style: AppTextStyles.tabular(AppTextStyles.label)
                        .copyWith(color: colors.text2),
                  ),
              ],
            ),
          ),
          for (final row in shown) ...[
            Divider(height: 1, color: colors.border),
            EndgameRowTile(row: row, roster: roster),
          ],
          if (hidden.isNotEmpty) ...[
            Divider(height: 1, color: colors.border),
            EndgameFold(
              title: l10n.rangeTitle(section.kind, hidden),
              summary: l10n.foldSummary(section.kind, hidden),
              rows: hidden,
              roster: roster,
            ),
          ],
        ],
      ),
    );
  }
}

class EndgameSectionFolds extends StatelessWidget {
  const EndgameSectionFolds({
    required this.sections,
    required this.roster,
    super.key,
  });

  final List<EndgameSection> sections;
  final Map<int, ChronicleCharacter> roster;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        children: [
          for (final (i, section) in sections.indexed) ...[
            if (i > 0) Divider(height: 1, color: colors.border),
            EndgameFold(
              title: l10n.sectionTitle(section),
              summary: switch ((section.stars, section.maxStars)) {
                (final stars?, final max?) => l10n.databookStarsValue(
                  stars,
                  max,
                ),
                _ => l10n.foldSummary(section.kind, section.rows),
              },
              rows: section.rows,
              roster: roster,
            ),
          ],
        ],
      ),
    );
  }
}
