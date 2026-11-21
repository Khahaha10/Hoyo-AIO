import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/game_labels.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

class RefreshingIndicator extends StatelessWidget {
  const RefreshingIndicator({required this.game, super.key});

  static const double _height = 76;
  static const double _bubble = 40;
  static const double _spinner = 22;
  static const double _stroke = 3;

  final Game game;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final label = l10n.dashboardUpdating(l10n.gameName(game));
    return Semantics(
      liveRegion: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        height: _height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: AppSpacing.s4,
          children: [
            Container(
              width: _bubble,
              height: _bubble,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
                boxShadow: context.elevation.card,
              ),
              child: SizedBox.square(
                dimension: _spinner,
                child: CircularProgressIndicator(
                  strokeWidth: _stroke,
                  color: context.gameAccent(game).acc,
                  backgroundColor: colors.surface3,
                ),
              ),
            ),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: colors.text2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
