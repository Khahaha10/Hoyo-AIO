import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/components/expedition_tile.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/domain/expedition.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:material_ui/material_ui.dart';

class ExpeditionListCard extends StatelessWidget {
  const ExpeditionListCard({
    required this.game,
    required this.title,
    required this.expeditions,
    required this.total,
    required this.now,
    required this.nameFor,
    super.key,
  });

  static const double _headerTop = 14;
  static const double _headerBottom = 6;

  final Game game;
  final String title;
  final List<Expedition> expeditions;
  final int total;
  final DateTime now;
  final String Function(int index, Expedition expedition) nameFor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final done = expeditions.where((e) => e.isDoneAt(now)).length;
    final count = total > 0 ? total : expeditions.length;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              _headerTop,
              AppSpacing.s16,
              _headerBottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: AppTextStyles.bodyL.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Text(
                  l10n.dashboardDoneCount(done, count),
                  style: AppTextStyles.tabular(
                    AppTextStyles.label,
                  ).copyWith(color: colors.text2, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          for (final (index, expedition) in expeditions.indexed)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: ExpeditionTile(
                game: game,
                name: nameFor(index, expedition),
                subtitle: expedition.isDoneAt(now)
                    ? l10n.dashboardReadyToCollect
                    : l10n.dashboardBackAt(l10n.clockTime(expedition.doneAt)),
                trailingText: l10n.duration(expedition.remainingAt(now)),
                isDone: expedition.isDoneAt(now),
                doneLabel: l10n.dashboardDone,
              ),
            ),
        ],
      ),
    );
  }
}
