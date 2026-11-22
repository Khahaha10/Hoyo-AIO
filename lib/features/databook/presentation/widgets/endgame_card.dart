import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';
import 'package:hoyo_aio/features/databook/presentation/databook_format.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class EndgameCard extends StatelessWidget {
  const EndgameCard({
    required this.summary,
    required this.now,
    this.onTap,
    super.key,
  });

  static const double _iconTile = 40;
  static const double _barHeight = 4;

  final EndgameSummary summary;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final accent = context.gameAccent(summary.mode.game);
    final progress = summary.attempted ? summary.progress : null;
    final name = l10n.modeName(summary.mode);
    return Semantics(
      button: onTap != null,
      label:
          '$name, ${l10n.endgameValue(summary)}, '
          '${l10n.endgameSubtitle(summary, now)}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.s8,
            children: [
              Row(
                spacing: AppSpacing.s12,
                children: [
                  Container(
                    width: _iconTile,
                    height: _iconTile,
                    decoration: BoxDecoration(
                      color: accent.soft,
                      borderRadius: BorderRadius.circular(AppRadius.iconTile),
                    ),
                    child: AppIcon(
                      endgameIcon(summary.mode),
                      color: accent.accInk,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.rowTitle.copyWith(
                            color: colors.text,
                          ),
                        ),
                        Text(
                          l10n.endgameSubtitle(summary, now),
                          style: AppTextStyles.caption.copyWith(
                            color: colors.text2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    l10n.endgameValue(summary),
                    textAlign: TextAlign.end,
                    style: AppTextStyles.tabular(AppTextStyles.rowTitle)
                        .copyWith(color: colors.text),
                  ),
                  if (onTap != null)
                    AppIcon(LucideIcons.chevronRight, color: colors.text3),
                ],
              ),
              if (progress != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: _barHeight,
                    color: accent.acc,
                    backgroundColor: colors.surface3,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
