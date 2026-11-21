import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/game_labels.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/codes/domain/redeem_code.dart';
import 'package:hoyo_aio/features/codes/presentation/code_format.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class CodeCard extends StatelessWidget {
  const CodeCard({
    required this.code,
    required this.now,
    required this.onCopy,
    required this.onRedeem,
    super.key,
  });

  static const double _redeemedOpacity = 0.72;
  static const _warnBefore = Duration(days: 2);
  static const double _codeSize = 20;
  static const double _codeSpacing = 1;

  final RedeemCode code;
  final DateTime now;
  final VoidCallback? onCopy;
  final VoidCallback? onRedeem;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final accent = context.gameAccent(code.game);
    final redeemed = code.redeemedAt != null;
    final expiresAt = code.expiresAt;
    final warn = expiresAt != null && expiresAt.difference(now) <= _warnBefore;
    final card = AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        14,
        AppSpacing.s16,
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s8,
        children: [
          Row(
            spacing: AppSpacing.s8,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent.acc,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                l10n.gameName(code.game),
                style: AppTextStyles.label.copyWith(color: colors.text2),
              ),
              if (redeemed)
                AppBadge(
                  label: l10n.codesRedeemed,
                  variant: AppBadgeVariant.success,
                )
              else if (code.unread)
                AppBadge(label: l10n.codesNew),
              const Spacer(),
              Text(
                l10n.lastUpdated(code.firstSeenAt, now),
                style: AppTextStyles.caption.copyWith(color: colors.text3),
              ),
            ],
          ),
          SelectableText(
            code.code,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: _codeSize,
              fontWeight: FontWeight.w700,
              letterSpacing: _codeSpacing,
              color: colors.text,
            ),
          ),
          Text(
            l10n.codeRewards(code.rewards),
            style: AppTextStyles.tabular(AppTextStyles.bodyM)
                .copyWith(color: colors.text2),
          ),
          Divider(height: AppSpacing.s8, color: colors.border),
          Row(
            spacing: AppSpacing.s8,
            children: [
              AppIcon(
                LucideIcons.clock,
                size: AppIconSize.badge,
                color: warn ? colors.warning : colors.text3,
              ),
              Expanded(
                child: Text(
                  switch ((code.redeemedAt, expiresAt)) {
                    (final at?, _) => l10n.codesRedeemedAt(_date(l10n, at)),
                    (_, final at?) => l10n.codesExpiresAt(_date(l10n, at)),
                    _ => l10n.codesNoExpiry,
                  },
                  style: AppTextStyles.caption.copyWith(
                    color: warn ? colors.warning : colors.text2,
                  ),
                ),
              ),
              if (onCopy case final copy?)
                AppIconButton(
                  icon: LucideIcons.copy,
                  semanticLabel: l10n.codesCopy,
                  onPressed: copy,
                ),
              if (onRedeem case final redeem?)
                AppButton(
                  label: redeemed ? l10n.codesAgain : l10n.codesRedeem,
                  size: AppButtonSize.small,
                  expand: false,
                  variant: redeemed
                      ? AppButtonVariant.secondary
                      : AppButtonVariant.primary,
                  onPressed: redeem,
                ),
            ],
          ),
        ],
      ),
    );
    return redeemed || onRedeem == null
        ? Opacity(opacity: _redeemedOpacity, child: card)
        : card;
  }

  static String _date(AppLocalizations l10n, DateTime at) =>
      '${DateFormat.MMMd(l10n.localeName).format(at.toLocal())} '
      '${l10n.clockTime(at)}';
}
