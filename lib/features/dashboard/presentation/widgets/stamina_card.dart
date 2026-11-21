import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/stamina_ring_card.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/domain/stamina.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:material_ui/material_ui.dart';

class StaminaCard extends StatelessWidget {
  const StaminaCard({
    required this.game,
    required this.label,
    required this.stamina,
    required this.now,
    required this.isStale,
    super.key,
  });

  final Game game;
  final String label;
  final Stamina stamina;
  final DateTime now;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isFull = stamina.isFullAt(now);
    final interval = stamina.recoveryInterval;
    if (isStale) {
      return StaminaRingCard(
        game: game,
        current: stamina.current,
        max: stamina.max,
        label: label,
        primaryText: l10n.dashboardAboutNow(
          l10n.number(stamina.currentAt(now)),
        ),
        secondaryText: l10n.dashboardEstimatedFrom(
          l10n.clockTime(stamina.fetchedAt),
        ),
        badgeLabel: l10n.dashboardStale,
        badgeVariant: AppBadgeVariant.warning,
        isStale: true,
      );
    }
    return StaminaRingCard(
      game: game,
      current: stamina.currentAt(now),
      max: stamina.max,
      label: label,
      primaryText: isFull
          ? l10n.dashboardFull
          : l10n.dashboardFullIn(l10n.duration(stamina.fullAt.difference(now))),
      secondaryText: isFull
          ? l10n.dashboardNotRecovering
          : l10n.atTime(stamina.fullAt, now),
      badgeLabel: interval > Duration.zero
          ? l10n.dashboardRecoveryRate(interval.inMinutes)
          : null,
    );
  }
}
