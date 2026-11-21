import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/info_banner.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/notifications/presentation/providers/notification_permission_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class NotificationPermissionBanner extends ConsumerStatefulWidget {
  const NotificationPermissionBanner({super.key});

  @override
  ConsumerState<NotificationPermissionBanner> createState() =>
      _NotificationPermissionBannerState();
}

class _NotificationPermissionBannerState
    extends ConsumerState<NotificationPermissionBanner> {
  late final _lifecycle = AppLifecycleListener(
    onResume: () =>
        unawaited(ref.read(notificationPermissionProvider.notifier).recheck()),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(notificationPermissionProvider).value;
    if (enabled ?? true) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.s12,
        children: [
          InfoBanner(
            icon: LucideIcons.bellOff,
            variant: InfoBannerVariant.warning,
            message: l10n.notificationPermissionBody,
          ),
          AppButton(
            label: l10n.notificationPermissionAllow,
            variant: AppButtonVariant.secondary,
            onPressed: () => unawaited(
              ref.read(notificationPermissionProvider.notifier).request(),
            ),
          ),
        ],
      ),
    );
  }
}
