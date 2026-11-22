import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/chronicle_avatar.dart';
import 'package:material_ui/material_ui.dart';

String constellationPrefix(Game game) => switch (game) {
  Game.genshin => 'C',
  Game.starRail => 'E',
  Game.zzz || Game.hi3 => 'M',
};

String rarityBadgeText(Game game, int rarity) => switch ((game, rarity)) {
  (Game.zzz, 5) => 'S',
  (Game.zzz, _) => 'A',
  _ => '$rarity★',
};

class CharacterCard extends StatelessWidget {
  const CharacterCard({
    required this.game,
    required this.character,
    required this.onTap,
    super.key,
  });

  static const double _avatar = 52;

  final Game game;
  final ChronicleCharacter character;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Semantics(
      button: true,
      label:
          '${character.name}, ${l10n.databookLevelShort(character.level)}, '
          '${constellationPrefix(game)}${character.constellation}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s8),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.banner),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Tag(
                    text: rarityBadgeText(game, character.rarity),
                    background: character.rarity >= 5
                        ? colors.warningBg
                        : context.gameAccent(Game.starRail).soft,
                    foreground: character.rarity >= 5
                        ? colors.warning
                        : context.gameAccent(Game.starRail).accInk,
                  ),
                  _Tag(
                    text:
                        '${constellationPrefix(game)}${character.constellation}',
                    background: colors.surface2,
                    foreground: colors.text2,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              ChronicleAvatar(
                name: character.name,
                element: character.element,
                imageUrl: character.iconUrl,
                rarity: character.rarity,
                size: _avatar,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                character.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(color: colors.text),
              ),
              Text(
                l10n.databookLevelShort(character.level),
                style: AppTextStyles.tabular(AppTextStyles.caption)
                    .copyWith(color: colors.text2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(
      text,
      style: AppTextStyles.tabular(AppTextStyles.badge)
          .copyWith(color: foreground, fontSize: 10),
    ),
  );
}
