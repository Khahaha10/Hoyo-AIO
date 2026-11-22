import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/presentation/chronicle_colors.dart';
import 'package:hoyo_aio/features/databook/presentation/providers/character_detail_provider.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/character_card.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/chronicle_avatar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

Future<void> showCharacterSheet(
  BuildContext context, {
  required SavedRole role,
  required ChronicleCharacter character,
}) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: context.colors.surface,
  barrierColor: context.colors.scrim,
  isScrollControlled: true,
  showDragHandle: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.dialog)),
  ),
  builder: (_) => CharacterSheet(role: role, character: character),
);

class CharacterSheet extends ConsumerWidget {
  const CharacterSheet({
    required this.role,
    required this.character,
    super.key,
  });

  static const double _avatar = 64;
  static const double _weaponIcon = 44;
  static const double _circle = 32;
  static const int _circleCount = 6;
  static const _levelCaps = {Game.genshin: 90, Game.starRail: 80, Game.zzz: 60};

  final SavedRole role;
  final ChronicleCharacter character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final game = role.game;
    final detail = ref.watch(characterDetailProvider(role, character.id));
    final weapon = detail.value?.data.weapon ?? character.weapon;
    final kind = character.kind;
    final subtitle = [
      rarityBadgeText(game, character.rarity),
      l10n.databookElementName(character.element),
      ?kind == null ? null : l10n.databookKindName(kind),
    ].join(' · ');
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s24,
            0,
            AppSpacing.s24,
            AppSpacing.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.s16,
            children: [
              Row(
                spacing: AppSpacing.s16,
                children: [
                  ChronicleAvatar(
                    name: character.name,
                    element: character.element,
                    imageUrl: character.iconUrl,
                    rarity: character.rarity,
                    size: _avatar,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            character.name,
                            style: AppTextStyles.titleL.copyWith(
                              color: colors.text,
                            ),
                          ),
                        ),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodyM.copyWith(
                            color: colors.text2,
                          ),
                        ),
                        Text(
                          l10n.databookLevelOf(
                            character.level,
                            _levelCaps[game] ?? character.level,
                          ),
                          style: AppTextStyles.tabular(AppTextStyles.rowTitle)
                              .copyWith(color: colors.text),
                        ),
                      ],
                    ),
                  ),
                  AppIconButton(
                    icon: LucideIcons.x,
                    semanticLabel: l10n.databookClose,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              _Constellation(game: game, character: character),
              if (weapon != null)
                _WeaponCard(game: game, weapon: weapon, kind: kind),
              if (character.friendship case final level?)
                Row(
                  spacing: AppSpacing.s8,
                  children: [
                    AppIcon(LucideIcons.heart, color: colors.text2),
                    Expanded(
                      child: Text(
                        l10n.databookFriendship,
                        style: AppTextStyles.bodyM.copyWith(color: colors.text),
                      ),
                    ),
                    Text(
                      l10n.databookFriendshipValue(level),
                      style: AppTextStyles.tabular(AppTextStyles.rowTitle)
                          .copyWith(color: colors.text),
                    ),
                  ],
                ),
              switch (detail) {
                AsyncValue(value: final result?)
                    when result.data.gear.isNotEmpty =>
                  _Gear(game: game, gear: result.data.gear),
                AsyncError() => Text(
                  l10n.databookGearFailed,
                  style: AppTextStyles.caption.copyWith(color: colors.text3),
                ),
                _ => const SizedBox.shrink(),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _Constellation extends StatelessWidget {
  const _Constellation({required this.game, required this.character});

  final Game game;
  final ChronicleCharacter character;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final fill = chronicleElementColor(character.element);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.s8,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.databookConstellationName(game.name),
                style: AppTextStyles.bodyM.copyWith(color: colors.text2),
              ),
            ),
            Text(
              '${constellationPrefix(game)}${character.constellation}',
              style: AppTextStyles.tabular(AppTextStyles.rowTitle)
                  .copyWith(color: colors.text),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 1; i <= CharacterSheet._circleCount; i++)
              Container(
                width: CharacterSheet._circle,
                height: CharacterSheet._circle,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= character.constellation ? fill : colors.surface2,
                ),
                child: Text(
                  '$i',
                  style: AppTextStyles.tabular(AppTextStyles.label).copyWith(
                    color: i <= character.constellation
                        ? colors.text
                        : colors.text3,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _WeaponCard extends StatelessWidget {
  const _WeaponCard({
    required this.game,
    required this.weapon,
    required this.kind,
  });

  final Game game;
  final ChronicleWeapon weapon;
  final String? kind;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final meta = l10n.databookWeaponMeta(
      kind == null ? '' : l10n.databookKindName(kind!),
      l10n.databookUpgradeName(game.name),
      weapon.refinement ?? 1,
      weapon.level,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Row(
        spacing: AppSpacing.s12,
        children: [
          ChronicleAvatar(
            name: weapon.name,
            element: null,
            imageUrl: weapon.iconUrl,
            rarity: weapon.rarity,
            size: CharacterSheet._weaponIcon,
            cornerRadius: AppRadius.iconTile,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.databookWeaponHeading(game.name).toUpperCase(),
                  style: AppTextStyles.overline.copyWith(color: colors.text3),
                ),
                Text(
                  weapon.name,
                  style: AppTextStyles.rowTitle.copyWith(color: colors.text),
                ),
                Text(
                  meta,
                  style: AppTextStyles.caption.copyWith(color: colors.text2),
                ),
              ],
            ),
          ),
          Text(
            rarityBadgeText(game, weapon.rarity),
            style: AppTextStyles.tabular(AppTextStyles.badge).copyWith(
              color: weapon.rarity >= 5 ? colors.warning : colors.text2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Gear extends StatelessWidget {
  const _Gear({required this.game, required this.gear});

  final Game game;
  final List<GearGroup> gear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.s8,
      children: [
        Row(
          spacing: AppSpacing.s8,
          children: [
            AppIcon(
              LucideIcons.layers,
              size: AppIconSize.inline,
              color: colors.text2,
            ),
            Text(
              l10n.databookGearHeading(game.name),
              style: AppTextStyles.bodyM.copyWith(color: colors.text2),
            ),
          ],
        ),
        for (final group in gear)
          Row(
            children: [
              Expanded(
                child: Text(
                  group.name,
                  style: AppTextStyles.rowTitle.copyWith(color: colors.text),
                ),
              ),
              if (group.pieces != null || group.upgrade != null)
                Text(
                  group.pieces != null
                      ? l10n.databookPieces(group.pieces!)
                      : l10n.databookUpgradeLevel(group.upgrade!),
                  style: AppTextStyles.tabular(AppTextStyles.bodyM)
                      .copyWith(color: colors.text2),
                ),
            ],
          ),
      ],
    );
  }
}
