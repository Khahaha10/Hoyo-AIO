import 'package:hoyo_aio/core/design_system/components/expedition_tile.dart';
import 'package:hoyo_aio/core/design_system/components/stat_tile.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';
import 'package:hoyo_aio/features/dashboard/domain/task_progress.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/dashboard_list_card.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/dashboard_shortcuts.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/progress_tile.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/stamina_card.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/tile_grid.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class ZzzLayout extends StatelessWidget {
  const ZzzLayout({
    required this.note,
    required this.now,
    required this.isStale,
    super.key,
  });

  static const _game = Game.zzz;

  final ZzzNote note;
  final DateTime now;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bounty = note.bountyCommission;
    final weekly = note.weeklyProgress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.s12,
      children: [
        StaminaCard(
          game: _game,
          label: l10n.zzzBattery,
          stamina: note.battery,
          now: now,
          isStale: isStale,
        ),
        TileGrid(
          isStale: isStale,
          tiles: [
            progressTile(
              game: _game,
              icon: LucideIcons.zap,
              label: l10n.zzzEngagement,
              progress: note.engagement,
              note: l10n.dashboardToday,
              l10n: l10n,
            ),
            StatTile(
              game: _game,
              icon: LucideIcons.ticket,
              label: l10n.zzzScratchCard,
              value: note.scratchCardDone
                  ? l10n.dashboardDone
                  : l10n.dashboardNotDone,
            ),
            StatTile(
              game: _game,
              icon: LucideIcons.film,
              label: l10n.zzzVideoStore,
              value: switch (note.videoStore) {
                VideoStoreState.closed => l10n.zzzVideoStoreClosed,
                VideoStoreState.open => l10n.zzzVideoStoreOpen,
                VideoStoreState.revenueReady => l10n.zzzVideoStoreRevenue,
              },
            ),
            if (bounty != null)
              progressTile(
                game: _game,
                icon: LucideIcons.target,
                label: l10n.zzzBountyCommission,
                progress: bounty,
                note: l10n.dashboardThisWeek,
                l10n: l10n,
              ),
          ],
        ),
        const DashboardShortcuts(),
        if (weekly != null || bounty != null)
          DashboardListCard(
            title: l10n.zzzWeeklyProgress,
            rows: [
              if (weekly != null)
                _row(l10n, l10n.zzzRiduWeekly, l10n.dashboardPoints, weekly),
              if (bounty != null)
                _row(
                  l10n,
                  l10n.zzzBountyCommissionFull,
                  l10n.dashboardThisWeek,
                  bounty,
                ),
            ],
          ),
      ],
    );
  }

  Widget _row(
    AppLocalizations l10n,
    String name,
    String subtitle,
    TaskProgress progress,
  ) => ExpeditionTile(
    game: _game,
    name: name,
    subtitle: subtitle,
    trailingText:
        '${l10n.number(progress.done)}/${l10n.number(progress.total)}',
    isDone: progress.isComplete,
    doneLabel: l10n.dashboardDone,
    showClock: false,
  );
}
