import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/chronicle_avatar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class CharactersCard extends StatelessWidget {
  const CharactersCard({
    required this.game,
    required this.characters,
    this.onSeeAll,
    super.key,
  });

  static const int _previewCount = 6;
  static const double _avatarSize = 42;
  static const double _countSize = 28;
  static const int _fiveStar = 5;
  static const int _fourStar = 4;

  final Game game;
  final List<ChronicleCharacter> characters;
  final VoidCallback? onSeeAll;

  List<ChronicleCharacter> get _top =>
      ([...characters]..sort(_byStrength)).take(_previewCount).toList();

  static int _byStrength(ChronicleCharacter a, ChronicleCharacter b) {
    final rarity = b.rarity.compareTo(a.rarity);
    if (rarity != 0) return rarity;
    final level = b.level.compareTo(a.level);
    if (level != 0) return level;
    return b.constellation.compareTo(a.constellation);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final isZzz = game == Game.zzz;
    final fiveStars = characters.where((c) => c.rarity == _fiveStar).length;
    final fourStars = characters.where((c) => c.rarity == _fourStar).length;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s12,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: AppSpacing.s8,
            children: [
              Text(
                l10n.number(characters.length),
                style: AppTextStyles.tabular(AppTextStyles.display).copyWith(
                  color: colors.text,
                  fontSize: _countSize,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Expanded(
                child: Text(
                  isZzz
                      ? l10n.databookAgentsLabel
                      : l10n.databookCharactersLabel,
                  style: AppTextStyles.bodyM.copyWith(color: colors.text2),
                ),
              ),
              if (onSeeAll != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSeeAll,
                  child: Row(
                    spacing: AppSpacing.s4,
                    children: [
                      Text(
                        l10n.databookSeeAll,
                        style: AppTextStyles.label.copyWith(color: colors.text),
                      ),
                      AppIcon(
                        LucideIcons.chevronRight,
                        size: AppIconSize.inline,
                        color: colors.text,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Row(
            spacing: AppSpacing.s8,
            children: [
              _RarityBadge(
                label: isZzz
                    ? l10n.databookRankBadge('S', fiveStars)
                    : l10n.databookRarityBadge(_fiveStar, fiveStars),
                background: colors.warningBg,
                foreground: colors.warning,
              ),
              _RarityBadge(
                label: isZzz
                    ? l10n.databookRankBadge('A', fourStars)
                    : l10n.databookRarityBadge(_fourStar, fourStars),
                background: context.gameAccent(Game.starRail).soft,
                foreground: context.gameAccent(Game.starRail).accInk,
              ),
            ],
          ),
          Row(
            spacing: AppSpacing.s8,
            children: [
              for (final character in _top)
                ChronicleAvatar(
                  name: character.name,
                  element: character.element,
                  imageUrl: character.iconUrl,
                  rarity: character.rarity,
                  size: _avatarSize,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(
      label,
      style: AppTextStyles.tabular(AppTextStyles.badge)
          .copyWith(color: foreground),
    ),
  );
}
