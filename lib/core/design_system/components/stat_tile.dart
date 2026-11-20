import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:material_ui/material_ui.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    required this.game,
    required this.icon,
    required this.label,
    required this.value,
    this.suffix,
    this.progress,
    this.note,
    super.key,
  });

  static const double _minHeight = 112;
  static const double _padding = 14;
  static const double _gap = 10;
  static const double _iconTile = 36;
  static const double _barHeight = 4;
  static const double _stackedTextScale = 1.15;

  final Game game;
  final IconData icon;
  final String label;
  final String value;
  final String? suffix;
  final double? progress;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = context.gameAccent(game);
    final labelText = Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.label.copyWith(color: colors.text2),
    );
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) > _stackedTextScale;
    return AppCard(
      padding: const EdgeInsets.all(_padding),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: _minHeight - _padding * 2 - 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: _gap,
          children: [
            Flex(
              direction: stacked ? Axis.vertical : Axis.horizontal,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: stacked
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              spacing: _gap,
              children: [
                Container(
                  width: _iconTile,
                  height: _iconTile,
                  decoration: BoxDecoration(
                    color: accent.soft,
                    borderRadius: BorderRadius.circular(AppRadius.iconTile),
                  ),
                  child: AppIcon(
                    icon,
                    size: AppIconSize.tile,
                    color: accent.accInk,
                  ),
                ),
                if (stacked) labelText else Expanded(child: labelText),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: AppTextStyles.tabular(AppTextStyles.titleL)
                          .copyWith(color: colors.text),
                    ),
                    if (suffix != null)
                      TextSpan(
                        text: suffix,
                        style: AppTextStyles.tabular(AppTextStyles.chip)
                            .copyWith(
                              fontWeight: FontWeight.w500,
                              color: colors.text3,
                            ),
                      ),
                  ],
                ),
                maxLines: 1,
              ),
            ),
            if (progress != null)
              Container(
                height: _barHeight,
                decoration: BoxDecoration(
                  color: colors.surface3,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress!.clamp(0, 1),
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.acc,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
            if (note != null)
              Text(
                note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  height: 14 / 11,
                  color: colors.text3,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
