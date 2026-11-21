import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_dialog.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_snackbar.dart';
import 'package:hoyo_aio/core/design_system/components/skeleton.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/error/app_exception_l10n.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/domain/account_summary.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:hoyo_aio/features/accounts/presentation/widgets/account_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  static const double _skeletonHeight = 220;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.s8,
            AppSpacing.gutter,
            AppSpacing.s24,
          ),
          children: [
            const _Header(),
            const SizedBox(height: AppSpacing.s8),
            ...switch (accounts) {
              AsyncData(:final value) => [
                for (final account in value) ...[
                  AccountCard(
                    account: account,
                    onRefreshCookie: () => context.push(AppRoutes.addAccount),
                    onDelete: () => _delete(context, ref, account),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                ],
              ],
              AsyncError(:final error) => [
                Text(
                  error is AppException
                      ? error.localizedMessage(context.l10n)
                      : context.l10n.errorUnknown,
                  style: AppTextStyles.bodyM.copyWith(
                    color: context.colors.danger,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
              ],
              _ => [
                const Skeleton(
                  child: SkeletonBox(
                    width: double.infinity,
                    height: _skeletonHeight,
                    radius: AppRadius.hero,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
              ],
            },
            AppButton(
              label: context.l10n.addAccountTitle,
              icon: LucideIcons.plus,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.push(AppRoutes.addAccount),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              context.l10n.accountsStorageNote,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: context.colors.text3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AccountSummary account,
  ) async {
    final l10n = context.l10n;
    final actions = ref.read(accountActionsProvider.notifier);
    try {
      final widgets = await actions.countWidgets(account.id);
      if (!context.mounted) return;
      final confirmed = await showAppConfirmDialog(
        context,
        icon: LucideIcons.trash2,
        title: l10n.deleteAccountTitle(account.nickname),
        body: l10n.deleteAccountBody(account.roles.length, widgets),
        cancelLabel: l10n.commonCancel,
        confirmLabel: l10n.accountsDelete,
      );
      if (!confirmed) return;
      await actions.delete(account.id);
      if (!context.mounted) return;
      showAppSnackbar(
        context,
        message: l10n.accountsDeleted(account.nickname),
        icon: LucideIcons.trash2,
      );
    } on AppException catch (e) {
      if (!context.mounted) return;
      showAppSnackbar(
        context,
        message: e.localizedMessage(l10n),
        icon: LucideIcons.circleAlert,
      );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      spacing: AppSpacing.s12,
      children: [
        if (context.canPop())
          AppIconButton(
            icon: LucideIcons.chevronLeft,
            semanticLabel: l10n.commonBack,
            onPressed: context.pop,
          ),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              l10n.accountsTitle,
              style: AppTextStyles.screenTitle.copyWith(
                color: context.colors.text,
              ),
            ),
          ),
        ),
        AppIconButton(
          icon: LucideIcons.plus,
          semanticLabel: l10n.addAccountTitle,
          onPressed: () => context.push(AppRoutes.addAccount),
        ),
      ],
    );
  }
}
