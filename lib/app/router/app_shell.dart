import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/core/design_system/components/app_bottom_nav_bar.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: [
          AppNavItem(icon: LucideIcons.house, label: l10n.navDashboard),
          AppNavItem(icon: LucideIcons.calendarCheck, label: l10n.navCheckIn),
          AppNavItem(icon: LucideIcons.layoutGrid, label: l10n.navWidgets),
          AppNavItem(icon: LucideIcons.settings, label: l10n.navSettings),
        ],
      ),
    );
  }
}
