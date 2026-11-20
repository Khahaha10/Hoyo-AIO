@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/design_system/components/alert_banner.dart';
import 'package:hoyo_aio/core/design_system/components/app_bottom_nav_bar.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/components/app_dialog.dart';
import 'package:hoyo_aio/core/design_system/components/app_toggle.dart';
import 'package:hoyo_aio/core/design_system/components/expedition_tile.dart';
import 'package:hoyo_aio/core/design_system/components/info_banner.dart';
import 'package:hoyo_aio/core/design_system/components/reward_day_cell.dart';
import 'package:hoyo_aio/core/design_system/components/settings_row.dart';
import 'package:hoyo_aio/core/design_system/components/skeleton.dart';
import 'package:hoyo_aio/core/design_system/components/stamina_ring_card.dart';
import 'package:hoyo_aio/core/design_system/components/stat_tile.dart';
import 'package:hoyo_aio/core/design_system/components/time_pill.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

void _noop() {}

const _tiles = [
  StatTile(
    game: Game.genshin,
    icon: LucideIcons.coins,
    label: 'Realm Currency',
    value: '1,840',
    suffix: '/2,400',
    progress: 0.77,
    note: 'Full in 9h',
  ),
  StatTile(
    game: Game.genshin,
    icon: LucideIcons.listChecks,
    label: 'Daily Commissions',
    value: '3',
    suffix: '/4',
    progress: 0.75,
    note: 'Bonus unclaimed',
  ),
];

class _SheetB extends StatelessWidget {
  const _SheetB();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTap: (_) {},
        items: const [
          AppNavItem(icon: LucideIcons.gauge, label: 'Dashboard'),
          AppNavItem(icon: LucideIcons.calendarCheck, label: 'Check-in'),
          AppNavItem(icon: LucideIcons.layoutGrid, label: 'Widgets'),
          AppNavItem(icon: LucideIcons.settings, label: 'Settings'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const StaminaRingCard(
            game: Game.genshin,
            current: 142,
            max: 200,
            label: 'Original Resin',
            primaryText: 'Full in 3h 12m',
            secondaryText: 'at 21:40 today',
            badgeLabel: '+1 every 8 min',
          ),
          const SizedBox(height: 12),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Expanded(
                child: StatTile(
                  game: Game.genshin,
                  icon: LucideIcons.coins,
                  label: 'Realm Currency',
                  value: '1,840',
                  suffix: '/2,400',
                  progress: 0.77,
                  note: 'Full in 9h',
                ),
              ),
              Expanded(
                child: StatTile(
                  game: Game.genshin,
                  icon: LucideIcons.listChecks,
                  label: 'Daily Commissions',
                  value: '3',
                  suffix: '/4',
                  progress: 0.75,
                  note: 'Bonus unclaimed',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const AppCard(
            child: Column(
              children: [
                ExpeditionTile(
                  game: Game.genshin,
                  name: 'Bennett',
                  subtitle: 'Expedition',
                  trailingText: '',
                  isDone: true,
                  doneLabel: 'Done',
                ),
                ExpeditionTile(
                  game: Game.genshin,
                  name: 'Xiangling',
                  subtitle: 'Expedition',
                  trailingText: '2h 14m',
                  isDone: false,
                  doneLabel: 'Done',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            spacing: 8,
            children: [
              Expanded(
                child: RewardDayCell(
                  day: 10,
                  icon: LucideIcons.gem,
                  quantity: '×20',
                  state: RewardDayState.claimed,
                  missedLabel: 'Missed',
                  semanticLabel: 'Day 10',
                ),
              ),
              Expanded(
                child: RewardDayCell(
                  day: 11,
                  icon: LucideIcons.gem,
                  quantity: '×20',
                  state: RewardDayState.missed,
                  missedLabel: 'Missed',
                  semanticLabel: 'Day 11',
                ),
              ),
              Expanded(
                child: RewardDayCell(
                  day: 20,
                  icon: LucideIcons.gem,
                  quantity: '×20',
                  state: RewardDayState.today,
                  missedLabel: 'Missed',
                  semanticLabel: 'Day 20',
                ),
              ),
              Expanded(
                child: RewardDayCell(
                  day: 21,
                  icon: LucideIcons.gift,
                  quantity: '×40',
                  state: RewardDayState.upcoming,
                  missedLabel: 'Missed',
                  semanticLabel: 'Day 21',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsCard(
            children: [
              const SettingsRow(
                icon: LucideIcons.languages,
                title: 'Language',
                value: 'English',
                onTap: _noop,
              ),
              SettingsRow(
                icon: LucideIcons.bell,
                title: 'Dailies Reminder',
                subtitle: 'If tasks are unfinished',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    const TimePill(
                      label: '21:00',
                      semanticLabel: 'Reminder time',
                      onTap: _noop,
                    ),
                    AppToggle(
                      value: true,
                      onChanged: (_) {},
                      semanticLabel: 'Dailies reminder',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const InfoBanner(
            icon: LucideIcons.shieldCheck,
            message: 'Stored on this device only. Your cookie is used just to talk to HoYoLAB.',
          ),
          const SizedBox(height: 12),
          const InfoBanner(
            icon: LucideIcons.triangleAlert,
            variant: InfoBannerVariant.warning,
            message: 'Never share your cookie. Anyone with it can use your HoYoLAB account.',
          ),
          const SizedBox(height: 12),
          const AlertBanner(
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
          const SizedBox(height: 12),
          const Skeleton(
            child: Row(
              spacing: 12,
              children: [
                SkeletonBox(width: 44, height: 44, isCircle: true),
                Expanded(child: SkeletonBox(width: null, height: 16)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AppConfirmDialog(
            icon: LucideIcons.trash2,
            title: 'Delete Kaz?',
            body: 'This removes the account, its 1 game role and 1 home widget from this device.',
            cancelLabel: 'Cancel',
            confirmLabel: 'Delete',
          ),
        ],
      ),
    );
  }
}

Future<void> _pumpSheet(
  WidgetTester tester,
  Widget sheet, {
  required bool dark,
  double textScale = 1,
  Size size = const Size(390, 1500),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: sheet,
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  for (final dark in [false, true]) {
    final name = dark ? 'dark' : 'light';
    testWidgets('components B sheet ($name)', (tester) async {
      await _pumpSheet(tester, const _SheetB(), dark: dark);
      await expectLater(
        find.byType(_SheetB),
        matchesGoldenFile('components_b_$name.png'),
      );
    });
  }

  testWidgets('stat tiles at 1.3x text scale', (tester) async {
    const sheet = Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Expanded(child: _Tile(0)),
          Expanded(child: _Tile(1)),
        ],
      ),
    );
    await _pumpSheet(
      tester,
      const Scaffold(body: sheet),
      dark: false,
      textScale: 1.3,
      size: const Size(390, 300),
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('stat_tile_1_3x.png'),
    );
  });
}

class _Tile extends StatelessWidget {
  const _Tile(this.index);

  final int index;

  @override
  Widget build(BuildContext context) => _tiles[index];
}
