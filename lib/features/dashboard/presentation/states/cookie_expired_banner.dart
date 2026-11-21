import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/components/alert_banner.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class CookieExpiredBanner extends StatelessWidget {
  const CookieExpiredBanner({
    required this.name,
    required this.dataFrom,
    required this.onLater,
    super.key,
  });

  final String name;
  final DateTime dataFrom;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertBanner(
      icon: LucideIcons.circleAlert,
      title: l10n.dashboardCookieExpiredTitle,
      body: l10n.dashboardCookieExpiredBody(name, l10n.clockTime(dataFrom)),
      actions: [
        AppButton(
          label: l10n.accountsRefreshCookie,
          size: AppButtonSize.small,
          expand: false,
          onPressed: () => context.push(AppRoutes.addAccount),
        ),
        AppButton(
          label: l10n.dashboardLater,
          variant: AppButtonVariant.text,
          expand: false,
          onPressed: onLater,
        ),
      ],
    );
  }
}
