import 'package:hoyo_aio/core/design_system/components/stat_tile.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/domain/game_note.dart';
import 'package:hoyo_aio/features/dashboard/domain/stamina.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/expedition_list_card.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/progress_tile.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/stamina_card.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/tile_grid.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class GenshinLayout extends StatelessWidget {
  const GenshinLayout({
    required this.note,
    required this.now,
    required this.isStale,
    super.key,
  });

  final GenshinNote note;
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
          game: Game.genshin,
          label: l10n.genshinResin,
          stamina: note.resin,
          now: now,
          isStale: isStale,
        ),
        TileGrid(
          isStale: isStale,
          tiles: [
            _realmCurrency(l10n),
            progressTile(
              game: Game.genshin,
              icon: LucideIcons.listChecks,
              label: l10n.genshinCommissions,
              progress: note.commissions,
              note: note.commissionBonusClaimed
                  ? l10n.dashboardBonusClaimed
                  : l10n.dashboardBonusUnclaimed,
              l10n: l10n,
            ),
            progressTile(
              game: Game.genshin,
              icon: LucideIcons.target,
              label: l10n.genshinWeeklyBosses,
              progress: note.weeklyBossDiscountsLeft,
              note: l10n.dashboardDiscountsLeft,
              l10n: l10n,
            ),
            _transformer(l10n),
          ],
        ),
        ExpeditionListCard(
          game: Game.genshin,
          title: l10n.genshinExpeditions,
          expeditions: note.expeditions,
          total: note.maxExpeditions,
          now: now,
          nameFor: (index, _) => l10n.genshinExpeditionName(index + 1),
        ),
      ],
    );
  }

  StatTile _realmCurrency(AppLocalizations l10n) {
    final Stamina coins = note.realmCurrency;
    final current = coins.currentAt(now);
    return StatTile(
      game: Game.genshin,
      icon: LucideIcons.coins,
      label: l10n.genshinRealmCurrency,
      value: l10n.number(current),
      suffix: '/${l10n.number(coins.max)}',
      progress: coins.max <= 0 ? null : current / coins.max,
      note: coins.isFullAt(now)
          ? l10n.dashboardFull
          : l10n.dashboardFullIn(l10n.duration(coins.fullAt.difference(now))),
    );
  }

  StatTile _transformer(AppLocalizations l10n) {
    final readyAt = note.transformerReadyAt;
    final remaining = readyAt?.difference(now);
    const cooldown = HoyolabConfig.genshinTransformerCooldown;
    final (
      String value,
      double? progress,
      String? tileNote,
    ) = switch (remaining) {
      null => (l10n.dashboardNotObtained, null, null),
      final left when left <= Duration.zero => (l10n.dashboardReady, 1.0, null),
      final left => (
        l10n.duration(left),
        (1 - left.inSeconds / cooldown.inSeconds).clamp(0.0, 1.0),
        l10n.dashboardUntilReady,
      ),
    };
    return StatTile(
      game: Game.genshin,
      icon: LucideIcons.repeat,
      label: l10n.genshinTransformer,
      value: value,
      progress: progress,
      note: tileNote,
    );
  }
}
