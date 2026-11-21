import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/error/app_exception_l10n.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

enum DashboardErrorAction { refreshCookie, openHoyolab, retry }

DashboardErrorAction dashboardErrorActionFor(Object error) => switch (error) {
  CookieExpiredException() => DashboardErrorAction.refreshCookie,
  CaptchaRequiredException() => DashboardErrorAction.openHoyolab,
  _ => DashboardErrorAction.retry,
};

String dashboardErrorMessage(Object error, AppLocalizations l10n) =>
    error is AppException ? error.localizedMessage(l10n) : l10n.errorUnknown;

Future<void> openHoyolab() => launchUrl(
  Uri.parse(HoyolabConfig.hoyolabHomeUrl),
  mode: LaunchMode.externalApplication,
);

class DashboardError extends StatelessWidget {
  const DashboardError({required this.error, required this.onRetry, super.key});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, icon, onPressed) = switch (dashboardErrorActionFor(error)) {
      DashboardErrorAction.refreshCookie => (
        l10n.accountsRefreshCookie,
        LucideIcons.refreshCw,
        () => context.push(AppRoutes.addAccount),
      ),
      DashboardErrorAction.openHoyolab => (
        l10n.dashboardOpenHoyolab,
        LucideIcons.externalLink,
        openHoyolab,
      ),
      DashboardErrorAction.retry => (
        l10n.commonRetry,
        LucideIcons.rotateCw,
        onRetry,
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s32),
      child: Column(
        spacing: AppSpacing.s16,
        children: [
          Text(
            dashboardErrorMessage(error, l10n),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyM.copyWith(color: context.colors.text2),
          ),
          AppButton(
            label: label,
            icon: icon,
            variant: AppButtonVariant.secondary,
            expand: false,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
