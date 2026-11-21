import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/design_system/components/game_switcher_chip.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/game_region.dart';
import 'package:hoyo_aio/core/l10n/game_labels.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    required this.role,
    required this.games,
    required this.onSelectGame,
    required this.onSwitchRole,
    required this.onRefresh,
    required this.onOpenCodes,
    required this.unreadCount,
    super.key,
  });

  static const double _avatar = 44;
  static const double _topPadding = 8;
  static const double _bottomPadding = 14;
  static const double _gap = 14;
  static const double _chipGap = 6;
  static const double _solidStop = 0.4;

  final SavedRole role;
  final List<Game> games;
  final ValueChanged<Game> onSelectGame;
  final VoidCallback? onSwitchRole;
  final VoidCallback? onRefresh;
  final VoidCallback onOpenCodes;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = context.gameAccent(role.game);
    final l10n = context.l10n;
    final region = switch (regionFromServerId(role.game, role.server)) {
      final region? => l10n.regionName(region),
      null => role.server,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.soft, accent.soft, accent.soft.withValues(alpha: 0)],
          stops: const [0, _solidStop, 1],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            _topPadding,
            AppSpacing.gutter,
            _bottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: _gap,
            children: [
              Row(
                spacing: AppSpacing.s12,
                children: [
                  _Avatar(name: role.nickname, game: role.game),
                  Expanded(
                    child: Semantics(
                      button: onSwitchRole != null,
                      label: l10n.dashboardSwitchRole,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onSwitchRole,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              spacing: AppSpacing.s4,
                              children: [
                                Flexible(
                                  child: Text(
                                    role.nickname,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.titleM.copyWith(
                                      color: colors.text,
                                    ),
                                  ),
                                ),
                                if (onSwitchRole != null)
                                  AppIcon(
                                    LucideIcons.chevronDown,
                                    size: AppIconSize.inline,
                                    color: colors.text2,
                                  ),
                              ],
                            ),
                            Text(
                              '${l10n.gameLevel(role.game, role.level)} · '
                              '$region · ${groupUid(role.uid)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.tabular(
                                AppTextStyles.rowSubtitle,
                              ).copyWith(color: colors.text2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _BellButton(
                    count: unreadCount,
                    label: l10n.codesTitle,
                    onPressed: onOpenCodes,
                  ),
                  AppIconButton(
                    icon: LucideIcons.refreshCw,
                    semanticLabel: l10n.dashboardRefresh,
                    onPressed: onRefresh,
                  ),
                ],
              ),
              Row(
                spacing: _chipGap,
                children: [
                  for (final game in games)
                    GameSwitcherChip(
                      game: game,
                      label: l10n.gameShortName(game),
                      selected: game == role.game,
                      onTap: () => onSelectGame(game),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.game});

  final String name;
  final Game game;

  @override
  Widget build(BuildContext context) {
    final accent = context.gameAccent(game);
    final initial = name.isEmpty
        ? '?'
        : String.fromCharCode(name.runes.first).toUpperCase();
    return Container(
      width: DashboardHeader._avatar,
      height: DashboardHeader._avatar,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: context.colors.border),
      ),
      child: ExcludeSemantics(
        child: Text(
          initial,
          style: AppTextStyles.bodyL.copyWith(
            color: accent.accInk,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({
    required this.count,
    required this.label,
    required this.onPressed,
  });

  static const double _badge = 20;
  static const double _ring = 2;
  static const double _offset = -4;
  static const double _badgePadding = 5;
  static const double _badgeFont = 11;

  final int count;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppIconButton(
          icon: LucideIcons.bell,
          semanticLabel: label,
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            top: _offset,
            right: _offset,
            child: Container(
              constraints: const BoxConstraints(minWidth: _badge),
              height: _badge,
              padding: const EdgeInsets.symmetric(horizontal: _badgePadding),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: BrandColors.lime,
                borderRadius: BorderRadius.circular(_badge),
                border: Border.all(color: colors.bg, width: _ring),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.tabular(AppTextStyles.badge).copyWith(
                  fontSize: _badgeFont,
                  fontWeight: FontWeight.w700,
                  color: BrandColors.ink,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
