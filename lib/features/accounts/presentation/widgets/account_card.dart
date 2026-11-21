import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/game_labels.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/domain/account_summary.dart';
import 'package:hoyo_aio/features/accounts/presentation/widgets/role_chip.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({
    required this.account,
    required this.onRefreshCookie,
    required this.onDelete,
    super.key,
  });

  static const double _avatar = 44;
  static const double _gap = 14;
  static const double _chipGap = 6;

  final AccountSummary account;
  final VoidCallback onRefreshCookie;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final roles = account.enabledRoles;
    return AppCard(
      radius: AppRadius.hero,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: _gap,
        children: [
          Row(
            spacing: AppSpacing.s12,
            children: [
              _Avatar(name: account.nickname),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.nickname,
                      style: AppTextStyles.bodyL.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l10n.accountsHoyolabId(groupUid(account.id)),
                      style: AppTextStyles.tabular(AppTextStyles.rowSubtitle)
                          .copyWith(color: colors.text2),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: account.status),
            ],
          ),
          if (roles.isEmpty)
            Text(
              l10n.accountsNoRoles,
              style: AppTextStyles.rowSubtitle.copyWith(color: colors.text2),
            )
          else
            Wrap(
              spacing: _chipGap,
              runSpacing: _chipGap,
              children: [for (final role in roles) RoleChip(role: role)],
            ),
          Text(
            _meta(l10n),
            style: AppTextStyles.rowSubtitle.copyWith(color: colors.text2),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s12),
              child: Row(
                children: [
                  AppButton(
                    label: l10n.accountsRefreshCookie,
                    icon: LucideIcons.refreshCw,
                    size: AppButtonSize.small,
                    expand: false,
                    variant: account.needsAttention
                        ? AppButtonVariant.primary
                        : AppButtonVariant.secondary,
                    onPressed: onRefreshCookie,
                  ),
                  const Spacer(),
                  AppButton(
                    label: l10n.accountsDelete,
                    icon: LucideIcons.trash2,
                    variant: AppButtonVariant.textDanger,
                    expand: false,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _meta(AppLocalizations l10n) {
    final time = DateFormat.MMMd(l10n.localeName)
        .add_Hm()
        .format(account.updatedAt.toLocal());
    return switch (account.status) {
      AccountStatus.valid => l10n.accountsMetaValid(time),
      AccountStatus.expired => l10n.accountsMetaExpired(time),
      AccountStatus.needsLogin => l10n.accountsMetaNeedsLogin,
    };
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initial = name.isEmpty
        ? '?'
        : String.fromCharCode(name.runes.first).toUpperCase();
    return Container(
      width: AccountCard._avatar,
      height: AccountCard._avatar,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface2,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
      ),
      child: ExcludeSemantics(
        child: Text(
          initial,
          style: AppTextStyles.bodyL.copyWith(
            color: colors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final AccountStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (status) {
      AccountStatus.valid => AppBadge(
        label: l10n.accountStatusValid,
        variant: AppBadgeVariant.success,
        icon: LucideIcons.check,
      ),
      AccountStatus.expired => AppBadge(
        label: l10n.accountStatusExpired,
        variant: AppBadgeVariant.danger,
        icon: LucideIcons.circleAlert,
      ),
      AccountStatus.needsLogin => AppBadge(
        label: l10n.accountStatusNeedsLogin,
        variant: AppBadgeVariant.warning,
        icon: LucideIcons.logIn,
      ),
    };
  }
}
