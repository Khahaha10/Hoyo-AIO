import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/settings_row.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final attention = ref.watch(accountsNeedingAttentionProvider);
    final count = ref.watch(accountsProvider).value?.length ?? 0;
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
          SettingsCard(
            children: [
              SettingsRow(
                icon: LucideIcons.users,
                title: l10n.settingsAccounts,
                subtitle: l10n.settingsAccountsCount(count),
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
        ],
      ),
    );
  }
}
