import 'package:hoyo_aio/core/design_system/components/stat_tile.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/domain/task_progress.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:material_ui/material_ui.dart';

StatTile progressTile({
  required Game game,
  required IconData icon,
  required String label,
  required TaskProgress progress,
  required AppLocalizations l10n,
  String? note,
}) => StatTile(
  game: game,
  icon: icon,
  label: label,
  value: l10n.number(progress.done),
  suffix: '/${l10n.number(progress.total)}',
  progress: progress.total <= 0
      ? null
      : (progress.done / progress.total).clamp(0.0, 1.0),
  note: note,
);
