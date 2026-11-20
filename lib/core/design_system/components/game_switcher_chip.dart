import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:material_ui/material_ui.dart';

class GameSwitcherChip extends StatelessWidget {
  const GameSwitcherChip({
    required this.game,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  static const chipKey = ValueKey('game-switcher-chip');
  static const double _height = 36;
  static const double _hitHeight = 44;
  static const double _dot = 8;

  final Game game;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = context.gameAccent(game);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: _hitHeight,
          child: Center(
            widthFactor: 1,
            child: Container(
              key: chipKey,
              height: _height,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
              decoration: BoxDecoration(
                color: selected ? accent.soft : colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: selected ? accent.acc : colors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.s8,
                children: [
                  Container(
                    width: _dot,
                    height: _dot,
                    decoration: BoxDecoration(
                      color: accent.acc,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    label,
                    style: AppTextStyles.chip.copyWith(
                      color: selected ? colors.text : colors.text2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
