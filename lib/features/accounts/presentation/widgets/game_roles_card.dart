import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/components/app_checkbox.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/game_labels.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/domain/detected_role.dart';
import 'package:material_ui/material_ui.dart';

class GameRolesCard extends StatelessWidget {
  const GameRolesCard({
    required this.game,
    required this.roles,
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final Game game;
  final List<DetectedRole> roles;
  final Set<DetectedRole> selected;
  final ValueChanged<DetectedRole> onToggle;

  static const double _dot = 8;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = context.gameAccent(game);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s12,
              AppSpacing.s16,
              AppSpacing.s4,
            ),
            child: Row(
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
                Expanded(
                  child: Text(
                    context.l10n.gameName(game).toUpperCase(),
                    style: AppTextStyles.overline.copyWith(color: colors.text2),
                  ),
                ),
              ],
            ),
          ),
          for (final role in roles)
            _RoleRow(
              role: role,
              checked: selected.contains(role),
              onToggle: () => onToggle(role),
            ),
        ],
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.role,
    required this.checked,
    required this.onToggle,
  });

  final DetectedRole role;
  final bool checked;
  final VoidCallback onToggle;

  static const double _minHeight = 56;
  static const double _avatar = 40;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = context.gameAccent(role.game);
    final l10n = context.l10n;
    final region = switch (role.region) {
      final region? => l10n.regionName(region),
      null => role.regionName ?? role.server,
    };
    final initial = role.nickname.isEmpty
        ? '?'
        : String.fromCharCode(role.nickname.runes.first).toUpperCase();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: Container(
        constraints: const BoxConstraints(minHeight: _minHeight),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s8,
          AppSpacing.s4,
          AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Row(
          spacing: AppSpacing.s12,
          children: [
            Container(
              width: _avatar,
              height: _avatar,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.soft,
                shape: BoxShape.circle,
              ),
              child: ExcludeSemantics(
                child: Text(
                  initial,
                  style: AppTextStyles.chip.copyWith(
                    color: accent.accInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${role.nickname} · ${l10n.gameLevel(role.game, role.level)}',
                    style: AppTextStyles.rowTitle.copyWith(color: colors.text),
                  ),
                  Text(
                    '$region · ${groupUid(role.uid)}',
                    style: AppTextStyles.tabular(AppTextStyles.rowSubtitle)
                        .copyWith(color: colors.text2),
                  ),
                ],
              ),
            ),
            AppCheckbox(
              value: checked,
              onChanged: (_) => onToggle(),
              semanticLabel: l10n.selectRolesRoleLabel(role.nickname, region),
            ),
          ],
        ),
      ),
    );
  }
}
