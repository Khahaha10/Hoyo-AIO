import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/dashboard_shortcuts.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/expedition_list_card.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/progress_tile.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/stamina_card.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/tile_grid.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class StarRailLayout extends StatelessWidget {
  const StarRailLayout({
    required this.note,
    required this.now,
    required this.isStale,
    super.key,
  });

  static const _game = Game.starRail;

  final StarRailNote note;
  final DateTime now;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.s12,
      children: [
        StaminaCard(
          game: _game,
          label: l10n.starRailTrailblazePower,
          stamina: note.trailblazePower,
          now: now,
          isStale: isStale,
        ),
        TileGrid(
          isStale: isStale,
          tiles: [
            progressTile(
              game: _game,
              icon: LucideIcons.listChecks,
              label: l10n.starRailDailyTraining,
              progress: note.dailyTraining,
              note: l10n.dashboardToday,
              l10n: l10n,
            ),
            progressTile(
              game: _game,
              icon: LucideIcons.swords,
              label: l10n.starRailEchoOfWar,
              progress: note.echoOfWarLeft,
              note: l10n.dashboardRewardsLeft,
              l10n: l10n,
            ),
            progressTile(
              game: _game,
              icon: LucideIcons.batteryCharging,
              label: l10n.starRailReservedPower,
              progress: note.reservedPower,
              note: note.reservedPower.isComplete ? l10n.dashboardFull : null,
              l10n: l10n,
            ),
            progressTile(
              game: _game,
              icon: LucideIcons.orbit,
              label: l10n.starRailSimulatedUniverse,
              progress: note.simulatedUniverse,
              note: l10n.dashboardThisWeek,
              l10n: l10n,
            ),
          ],
        ),
        const DashboardShortcuts(),
        if (note.assignments.isNotEmpty)
          ExpeditionListCard(
            game: _game,
            title: l10n.starRailAssignments,
            expeditions: note.assignments,
            total: note.maxAssignments,
            now: now,
            nameFor: (index, assignment) => switch (assignment.name) {
              final name? when name.trim().isNotEmpty => name,
              _ => l10n.starRailAssignmentName(index + 1),
            },
          ),
      ],
    );
  }
}
