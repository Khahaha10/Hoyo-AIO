import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/app_settings_provider.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/settings_row.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/selected_role_provider.dart';
import 'package:hoyo_aio/features/notifications/presentation/notification_permission_banner.dart';
import 'package:hoyo_aio/features/notifications/presentation/providers/notification_sync_provider.dart';
import 'package:hoyo_aio/features/settings/presentation/appearance_card.dart';
import 'package:hoyo_aio/features/settings/presentation/profile_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final attention = ref.watch(accountsNeedingAttentionProvider);
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final notifications = ref.watch(notificationSettingsProvider).value;
    final preferences = ref.watch(appPreferencesProvider).value;
    final selectedAccountId = ref.watch(selectedRoleProvider)?.accountId;
    final profile = [
      ...accounts.where((account) => account.id == selectedAccountId),
      ...accounts,
    ].firstOrNull;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.navSettings,
              style: AppTextStyles.headline.copyWith(color: colors.text),
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          const NotificationPermissionBanner(),
          if (profile != null)
            ProfileCard(
              profile: profile,
              accounts: accounts,
              onTap: () => context.push(AppRoutes.accounts),
            ),
          if (preferences != null) ...[
            _SectionLabel(l10n.settingsAppearanceSection),
            AppearanceCard(preferences: preferences),
          ],
          _SectionLabel(l10n.settingsGeneralSection),
          SettingsCard(
            children: [
              SettingsRow(
                icon: LucideIcons.bell,
                title: l10n.notificationsTitle,
                value: switch (notifications) {
                  null => null,
                  final settings when !settings.enabled =>
                    l10n.settingsNotificationsOff,
                  final settings => l10n.settingsNotificationsOn(
                    settings.activeAlertCount,
                  ),
                },
                onTap: () => context.push(AppRoutes.notifications),
              ),
              SettingsRow(
                icon: LucideIcons.users,
                title: l10n.settingsAccounts,
                onTap: () => context.push(AppRoutes.accounts),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.s4,
                  children: [
                    if (attention > 0)
                      AppBadge(
                        label: l10n.settingsNeedsAttention(attention),
                        variant: AppBadgeVariant.danger,
                      ),
                    AppIcon(LucideIcons.chevronRight, color: colors.text3),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s24),
            child: Text(
              '${l10n.splashDisclaimerUnofficial} · '
              '${l10n.splashDisclaimerNotAffiliated}',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: colors.text3),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.s4,
      AppSpacing.s24,
      AppSpacing.s4,
      AppSpacing.s8,
    ),
    child: Text(
      text.toUpperCase(),
      style: AppTextStyles.overline.copyWith(color: context.colors.text2),
    ),
  );
}
