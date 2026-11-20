import 'package:hoyo_aio/core/design_system/components/alert_banner.dart';
import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/app_bottom_nav_bar.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_dialog.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_snackbar.dart';
import 'package:hoyo_aio/core/design_system/components/info_banner.dart';
import 'package:hoyo_aio/core/design_system/components/skeleton.dart';
import 'package:hoyo_aio/core/design_system/gallery/content_demos.dart';
import 'package:hoyo_aio/core/design_system/gallery/control_demos.dart';
import 'package:hoyo_aio/core/design_system/gallery/gallery_section.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

void _noop() {}

List<Widget> componentSections() => const [
  GallerySection(title: 'Buttons', children: [_ButtonsDemo()]),
  GallerySection(title: 'Controls', children: [ControlsDemo()]),
  GallerySection(title: 'Badges', children: [_BadgesDemo()]),
  GallerySection(title: 'Cards', children: [CardsDemo()]),
  GallerySection(title: 'Check-in Calendar', children: [RewardCellsDemo()]),
  GallerySection(title: 'Settings Rows', children: [SettingsDemo()]),
  GallerySection(title: 'Banners', children: [_BannersDemo()]),
  GallerySection(title: 'Feedback', children: [_FeedbackDemo()]),
  GallerySection(title: 'Navigation', children: [_NavDemo()]),
];

class _ButtonsDemo extends StatelessWidget {
  const _ButtonsDemo();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpacing.s12,
    children: [
      GalleryLabel('Primary · default / disabled / loading'),
      AppButton(
        label: 'Check In Now',
        icon: LucideIcons.calendarCheck,
        onPressed: _noop,
      ),
      AppButton(label: 'Check In Now', onPressed: null),
      AppButton(label: 'Checking In…', onPressed: _noop, isLoading: true),
      GalleryLabel('Secondary · danger · sizes'),
      AppButton(
        label: 'Later',
        variant: AppButtonVariant.secondary,
        onPressed: _noop,
      ),
      AppButton(
        label: 'Delete',
        variant: AppButtonVariant.danger,
        size: AppButtonSize.medium,
        onPressed: _noop,
      ),
      Wrap(
        spacing: AppSpacing.s8,
        runSpacing: AppSpacing.s8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppButton(
            label: 'Refresh Cookie',
            size: AppButtonSize.small,
            expand: false,
            onPressed: _noop,
          ),
          AppButton(
            label: 'How It Works',
            variant: AppButtonVariant.text,
            expand: false,
            onPressed: _noop,
          ),
          AppIconButton(
            icon: LucideIcons.refreshCw,
            semanticLabel: 'Refresh',
            onPressed: _noop,
          ),
          AppIconButton(
            icon: LucideIcons.bell,
            semanticLabel: 'Notifications',
            onPressed: null,
          ),
        ],
      ),
    ],
  );
}

class _BadgesDemo extends StatelessWidget {
  const _BadgesDemo();

  @override
  Widget build(BuildContext context) => const Wrap(
    spacing: AppSpacing.s8,
    runSpacing: AppSpacing.s8,
    children: [
      AppBadge(label: '+1 every 8 min'),
      AppBadge(
        label: 'Done',
        variant: AppBadgeVariant.success,
        icon: LucideIcons.check,
      ),
      AppBadge(label: '1 needs attention', variant: AppBadgeVariant.danger),
      AppBadge(label: 'Stale', variant: AppBadgeVariant.warning),
    ],
  );
}

class _BannersDemo extends StatelessWidget {
  const _BannersDemo();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpacing.s12,
    children: [
      InfoBanner(
        icon: LucideIcons.shieldCheck,
        message: 'Stored on this device only. Your cookie is used just to talk to HoYoLAB and is never sent to us.',
      ),
      InfoBanner(
        icon: LucideIcons.triangleAlert,
        variant: InfoBannerVariant.warning,
        message: 'Never share your cookie. Anyone with it can use your HoYoLAB account.',
      ),
      AlertBanner(
        icon: LucideIcons.cookie,
        title: 'Cookie Expired',
        body: 'HoYoLAB rejected the saved cookie for Aiko. Showing data from 18:06.',
        actions: [
          AppButton(
            label: 'Refresh Cookie',
            size: AppButtonSize.small,
            expand: false,
            onPressed: _noop,
          ),
          AppButton(
            label: 'Later',
            variant: AppButtonVariant.text,
            expand: false,
            onPressed: _noop,
          ),
        ],
      ),
    ],
  );
}

class _FeedbackDemo extends StatelessWidget {
  const _FeedbackDemo();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpacing.s12,
    children: [
      const GalleryLabel('Skeleton'),
      const Skeleton(
        child: Row(
          spacing: AppSpacing.s12,
          children: [
            SkeletonBox(width: 44, height: 44, isCircle: true),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.s8,
                children: [
                  SkeletonBox(width: 140, height: 16),
                  SkeletonBox(width: 200, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
      const GalleryLabel('Snackbar · dialog'),
      Wrap(
        spacing: AppSpacing.s8,
        runSpacing: AppSpacing.s8,
        children: [
          AppButton(
            label: 'Success',
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.small,
            expand: false,
            onPressed: () => showAppSnackbar(
              context,
              message: 'Checked in to 3 games',
              icon: LucideIcons.circleCheck,
            ),
          ),
          AppButton(
            label: 'Error',
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.small,
            expand: false,
            onPressed: () => showAppSnackbar(
              context,
              message: "Couldn't reach HoYoLAB",
              icon: LucideIcons.wifiOff,
              actionLabel: 'Retry',
              onAction: _noop,
            ),
          ),
          AppButton(
            label: 'Dialog',
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.small,
            expand: false,
            onPressed: () => showAppConfirmDialog(
              context,
              icon: LucideIcons.trash2,
              title: 'Delete Kaz?',
              body: 'This removes the account, its 1 game role and 1 home widget from this device. Your HoYoLAB account is not affected.',
              cancelLabel: 'Cancel',
              confirmLabel: 'Delete',
            ),
          ),
        ],
      ),
    ],
  );
}

class _NavDemo extends StatefulWidget {
  const _NavDemo();

  @override
  State<_NavDemo> createState() => _NavDemoState();
}

class _NavDemoState extends State<_NavDemo> {
  var _index = 0;

  @override
  Widget build(BuildContext context) => MediaQuery.removeViewPadding(
    context: context,
    removeBottom: true,
    child: AppBottomNavBar(
      currentIndex: _index,
      onTap: (i) => setState(() => _index = i),
      items: const [
        AppNavItem(icon: LucideIcons.gauge, label: 'Dashboard'),
        AppNavItem(icon: LucideIcons.calendarCheck, label: 'Check-in'),
        AppNavItem(icon: LucideIcons.layoutGrid, label: 'Widgets'),
        AppNavItem(icon: LucideIcons.settings, label: 'Settings'),
      ],
    ),
  );
}
