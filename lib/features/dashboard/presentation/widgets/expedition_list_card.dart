import 'package:hoyo_aio/core/design_system/components/expedition_tile.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/domain/expedition.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/dashboard_list_card.dart';
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

  final Game game;
  final String title;
  final List<Expedition> expeditions;
  final int total;
  final DateTime now;
  final String Function(int index, Expedition expedition) nameFor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final done = expeditions.where((e) => e.isDoneAt(now)).length;
    final count = total > 0 ? total : expeditions.length;
    return DashboardListCard(
      title: title,
      trailing: l10n.dashboardDoneCount(done, count),
      rows: [
        for (final (index, expedition) in expeditions.indexed)
          ExpeditionTile(
            game: game,
            name: nameFor(index, expedition),
            subtitle: expedition.isDoneAt(now)
                ? l10n.dashboardReadyToCollect
                : l10n.dashboardBackAt(l10n.clockTime(expedition.doneAt)),
            trailingText: l10n.duration(expedition.remainingAt(now)),
            isDone: expedition.isDoneAt(now),
            doneLabel: l10n.dashboardDone,
          ),
      ],
    );
  }
}
