import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/design_system/components/alert_banner.dart';
import 'package:hoyo_aio/core/design_system/components/app_bottom_nav_bar.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_dialog.dart';
import 'package:hoyo_aio/core/design_system/components/app_snackbar.dart';
import 'package:hoyo_aio/core/design_system/components/info_banner.dart';
import 'package:hoyo_aio/core/design_system/components/settings_row.dart';
import 'package:hoyo_aio/core/design_system/components/skeleton.dart';
import 'package:hoyo_aio/core/design_system/components/time_pill.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/app_colors.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_themed.dart';

void main() {
  group('SettingsRow', () {
    testWidgets('shows value and chevron and taps', (tester) async {
      var taps = 0;
      await pumpThemed(
        tester,
        SettingsRow(
          icon: LucideIcons.languages,
          title: 'Language',
          value: 'English',
          onTap: () => taps++,
        ),
      );
      expect(find.text('English'), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
      expect(
        tester.getSize(find.byType(SettingsRow)).height,
        greaterThanOrEqualTo(56),
      );
      await tester.tap(find.byType(SettingsRow));
      expect(taps, 1);
    });

    testWidgets('custom trailing replaces the chevron', (tester) async {
      await pumpThemed(
        tester,
        SettingsRow(
          icon: LucideIcons.clock,
          title: 'Run Time',
          trailing: TimePill(
            label: '20:00',
            semanticLabel: 'Run time 20:00',
            onTap: () {},
          ),
        ),
      );
      expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
      expect(find.text('20:00'), findsOneWidget);
      expect(tester.getSize(find.byType(TimePill)).height, 36);
    });

    testWidgets('SettingsCard separates rows with a divider', (tester) async {
      await pumpThemed(
        tester,
        const SettingsCard(
          children: [
            SettingsRow(icon: LucideIcons.bell, title: 'A'),
            SettingsRow(icon: LucideIcons.bell, title: 'B'),
            SettingsRow(icon: LucideIcons.bell, title: 'C'),
          ],
        ),
      );
      expect(find.byType(Divider), findsNWidgets(2));
    });
  });

  group('Banners', () {
    testWidgets('info banner uses surface-2', (tester) async {
      await pumpThemed(
        tester,
        const InfoBanner(
          icon: LucideIcons.shieldCheck,
          message: 'Stored on this device only.',
        ),
      );
      final d =
          tester.widget<Container>(find.byType(Container).first).decoration!
              as BoxDecoration;
      expect(d.color, AppColors.light.surface2);
    });

    testWidgets('warning banner uses the warning tint', (tester) async {
      await pumpThemed(
        tester,
        const InfoBanner(
          icon: LucideIcons.triangleAlert,
          message: 'Never share your cookie.',
          variant: InfoBannerVariant.warning,
        ),
      );
      final d =
          tester.widget<Container>(find.byType(Container).first).decoration!
              as BoxDecoration;
      expect(d.color, AppColors.light.warningBg);
    });

    testWidgets('alert banner shows title, body and actions', (tester) async {
      await pumpThemed(
        tester,
        AlertBanner(
          icon: LucideIcons.cookie,
          title: 'Cookie Expired',
          body: 'HoYoLAB rejected the saved cookie.',
          actions: [
            AppButton(
              label: 'Refresh Cookie',
              size: AppButtonSize.small,
              expand: false,
              onPressed: () {},
            ),
          ],
        ),
      );
      expect(find.text('Cookie Expired'), findsOneWidget);
      expect(find.text('Refresh Cookie'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.byType(AlertBanner))
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
    });
  });

  group('Skeleton', () {
    testWidgets('renders a surface-3 block', (tester) async {
      await pumpThemed(
        tester,
        const Skeleton(child: SkeletonBox(width: 120, height: 16)),
      );
      await tester.pump(const Duration(milliseconds: 600));
      final box = tester.widget<Container>(find.byType(Container).last);
      expect(
        (box.decoration! as BoxDecoration).color,
        AppColors.light.surface3,
      );
      expect(tester.getSize(find.byType(SkeletonBox)), const Size(120, 16));
    });

    testWidgets('does not animate when motion is reduced', (tester) async {
      await pumpThemed(
        tester,
        const Skeleton(child: SkeletonBox(width: 120, height: 16)),
        disableAnimations: true,
      );
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('AppButton sizes and danger variant', () {
    testWidgets('small is 44, medium is 48', (tester) async {
      await pumpThemed(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              key: const Key('s'),
              label: 'S',
              size: AppButtonSize.small,
              onPressed: () {},
            ),
            AppButton(
              key: const Key('m'),
              label: 'M',
              size: AppButtonSize.medium,
              onPressed: () {},
            ),
          ],
        ),
      );
      expect(tester.getSize(find.byKey(const Key('s'))).height, 44);
      expect(tester.getSize(find.byKey(const Key('m'))).height, 48);
    });

    testWidgets('danger is filled with danger and bg-colored text', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        AppButton(
          label: 'Delete',
          variant: AppButtonVariant.danger,
          onPressed: () {},
        ),
      );
      expect(
        tester.widget<Text>(find.text('Delete')).style?.color,
        AppColors.light.bg,
      );
    });
  });

  group('showAppConfirmDialog', () {
    Future<bool?> open(WidgetTester tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showAppConfirmDialog(
                    context,
                    icon: LucideIcons.trash2,
                    title: 'Delete Kaz?',
                    body: 'This removes the account from this device.',
                    cancelLabel: 'Cancel',
                    confirmLabel: 'Delete',
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('returns true on confirm', (tester) async {
      await open(tester);
      expect(find.text('Delete Kaz?'), findsOneWidget);
      final barrier = tester.widget<ModalBarrier>(
        find.byType(ModalBarrier).last,
      );
      expect(barrier.color, AppColors.light.scrim);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Kaz?'), findsNothing);
    });

    testWidgets('returns false on cancel', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showAppConfirmDialog(
                context,
                icon: LucideIcons.trash2,
                title: 'T',
                body: 'B',
                cancelLabel: 'Cancel',
                confirmLabel: 'Delete',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });

  group('showAppSnackbar', () {
    testWidgets('shows message on inverse surface with a lime action', (
      tester,
    ) async {
      var retried = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAppSnackbar(
                  context,
                  message: "Couldn't reach HoYoLAB",
                  icon: LucideIcons.wifiOff,
                  actionLabel: 'Retry',
                  onAction: () => retried++,
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      final bar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(bar.backgroundColor, AppColors.light.inverse);
      expect(bar.duration, const Duration(seconds: 6));
      expect(
        tester.widget<Text>(find.text('Retry')).style?.color,
        BrandColors.lime,
      );
      await tester.tap(find.text('Retry'));
      expect(retried, 1);
    });
  });

  group('AppBottomNavBar', () {
    testWidgets('highlights the active item and reports taps', (tester) async {
      int? tapped;
      await pumpThemed(
        tester,
        AppBottomNavBar(
          currentIndex: 0,
          onTap: (i) => tapped = i,
          items: const [
            AppNavItem(icon: LucideIcons.gauge, label: 'Dashboard'),
            AppNavItem(icon: LucideIcons.calendarCheck, label: 'Check-in'),
            AppNavItem(icon: LucideIcons.layoutGrid, label: 'Widgets'),
            AppNavItem(icon: LucideIcons.settings, label: 'Settings'),
          ],
        ),
      );
      expect(
        tester.widget<Text>(find.text('Dashboard')).style?.fontWeight,
        FontWeight.w700,
      );
      expect(
        tester.widget<Text>(find.text('Widgets')).style?.color,
        AppColors.light.text3,
      );
      expect(tester.getSize(find.byType(AppBottomNavBar)).height, 88);
      await tester.tap(find.text('Settings'));
      expect(tapped, 3);
      expect(
        tester.getSemantics(find.text('Dashboard')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
    });
  });
}
