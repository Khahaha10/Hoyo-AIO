import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class ExpeditionTile extends StatelessWidget {
  const ExpeditionTile({
    required this.game,
    required this.name,
    required this.subtitle,
    required this.trailingText,
    required this.isDone,
    required this.doneLabel,
    super.key,
  });

  static const double _minHeight = 60;
  static const double _avatar = 40;

  final Game game;
  final String name;
  final String subtitle;
  final String trailingText;
  final bool isDone;
  final String doneLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = context.gameAccent(game);
    final initial = name.isEmpty ? '' : name.characters.first.toUpperCase();
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: 10,
        ),
        child: Row(
          spacing: 14,
          children: [
            Container(
              width: _avatar,
              height: _avatar,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.soft,
                shape: BoxShape.circle,
              ),
              child: Text(
                initial,
                style: AppTextStyles.chip.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent.accInk,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.rowTitle.copyWith(color: colors.text),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.rowSubtitle.copyWith(
                      color: colors.text2,
                    ),
                  ),
                ],
              ),
            ),
            if (isDone)
              AppBadge(
                label: doneLabel,
                variant: AppBadgeVariant.success,
                icon: LucideIcons.check,
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.s4,
                children: [
                  AppIcon(
                    LucideIcons.clock,
                    size: AppIconSize.badge,
                    color: colors.text3,
                  ),
                  Text(
                    trailingText,
                    style: AppTextStyles.tabular(AppTextStyles.chip)
                        .copyWith(color: colors.text),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
