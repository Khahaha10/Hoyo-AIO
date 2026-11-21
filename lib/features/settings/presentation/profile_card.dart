import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/domain/account_summary.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    required this.profile,
    required this.accounts,
    required this.onTap,
    super.key,
  });

  static const double _avatar = 44;

  final AccountSummary profile;
  final List<AccountSummary> accounts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final roleCount = accounts.fold(
      0,
      (sum, account) => sum + account.enabledRoles.length,
    );
    final initial = profile.nickname.isEmpty
        ? '?'
        : String.fromCharCode(profile.nickname.runes.first).toUpperCase();
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Row(
            spacing: AppSpacing.s12,
            children: [
              Container(
                width: _avatar,
                height: _avatar,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: BrandColors.lime,
                  shape: BoxShape.circle,
                ),
                child: ExcludeSemantics(
                  child: Text(
                    initial,
                    style: AppTextStyles.titleM.copyWith(
                      color: BrandColors.ink,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.nickname,
                      style: AppTextStyles.titleM.copyWith(color: colors.text),
                    ),
                    Text(
                      '${l10n.settingsAccountsCount(accounts.length)} · '
                      '${l10n.settingsRolesCount(roleCount)}',
                      style: AppTextStyles.rowSubtitle.copyWith(
                        color: colors.text2,
                      ),
                    ),
                  ],
                ),
              ),
              AppIcon(LucideIcons.chevronRight, color: colors.text3),
            ],
          ),
        ),
      ),
    );
  }
}
