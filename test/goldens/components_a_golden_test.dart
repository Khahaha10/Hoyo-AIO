@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_checkbox.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_segmented_control.dart';
import 'package:hoyo_aio/core/design_system/components/app_slider.dart';
import 'package:hoyo_aio/core/design_system/components/app_swatch_picker.dart';
import 'package:hoyo_aio/core/design_system/components/app_toggle.dart';
import 'package:hoyo_aio/core/design_system/components/game_switcher_chip.dart';
import 'package:hoyo_aio/core/design_system/components/radio_option_card.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

void _noop() {}
void _noopBool(bool _) {}

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const AppButton(
          label: 'Check In Now',
          icon: LucideIcons.calendarCheck,
          onPressed: _noop,
        ),
        const SizedBox(height: 12),
        const AppButton(label: 'Check In Now', onPressed: null),
        const SizedBox(height: 12),
        const AppButton(
          label: 'Checking In…',
          onPressed: _noop,
          isLoading: true,
        ),
        const SizedBox(height: 12),
        const AppButton(
          label: 'Later',
          variant: AppButtonVariant.secondary,
          onPressed: _noop,
        ),
        const Row(
          children: [
            AppButton(
              label: 'How It Works',
              variant: AppButtonVariant.text,
              onPressed: _noop,
              expand: false,
            ),
            AppIconButton(
              icon: LucideIcons.refreshCw,
              semanticLabel: 'Refresh',
              onPressed: _noop,
            ),
            SizedBox(width: 8),
            AppIconButton(
              icon: LucideIcons.bell,
              semanticLabel: 'Notifications',
              onPressed: null,
            ),
          ],
        ),
        const Wrap(
          spacing: 8,
          children: [
            GameSwitcherChip(
              game: Game.genshin,
              label: 'Genshin',
              selected: true,
              onTap: _noop,
            ),
            GameSwitcherChip(
              game: Game.starRail,
              label: 'Star Rail',
              selected: false,
              onTap: _noop,
            ),
            GameSwitcherChip(
              game: Game.zzz,
              label: 'ZZZ',
              selected: false,
              onTap: _noop,
            ),
          ],
        ),
        const Row(
          spacing: 12,
          children: [
            AppToggle(value: false, onChanged: _noopBool, semanticLabel: 'a'),
            AppToggle(value: true, onChanged: _noopBool, semanticLabel: 'b'),
            AppToggle(value: true, onChanged: null, semanticLabel: 'c'),
            AppCheckbox(value: false, onChanged: _noopBool, semanticLabel: 'd'),
            AppCheckbox(value: true, onChanged: _noopBool, semanticLabel: 'e'),
          ],
        ),
        AppSlider(
          value: 90,
          min: 50,
          max: 100,
          onChanged: (_) {},
          semanticLabel: 'Stamina threshold',
        ),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppBadge(label: '+1 every 8 min'),
            AppBadge(
              label: 'Done',
              variant: AppBadgeVariant.success,
              icon: LucideIcons.check,
            ),
            AppBadge(label: 'Expired', variant: AppBadgeVariant.danger),
            AppBadge(label: 'Stale', variant: AppBadgeVariant.warning),
          ],
        ),
        AppSegmentedControl<String>(
          options: const [
            SegmentOption(value: 'system', label: 'System'),
            SegmentOption(value: 'light', label: 'Light'),
            SegmentOption(value: 'dark', label: 'Dark'),
          ],
          selected: 'system',
          onChanged: (_) {},
        ),
        AppSwatchPicker<String>(
          options: const [
            SwatchOption(
              value: 'match',
              label: 'Match game',
              colors: [
                Color(0xFF4A90E2),
                Color(0xFF8B7CF6),
                Color(0xFFF5C518),
                Color(0xFFE94B6A),
              ],
            ),
            SwatchOption(
              value: 'lime',
              label: 'Lime',
              colors: [Color(0xFFD2E843)],
            ),
            SwatchOption(
              value: 'blue',
              label: 'Blue',
              colors: [Color(0xFF4A90E2)],
            ),
          ],
          selected: 'match',
          onChanged: (_) {},
        ),
        const SizedBox(height: 8),
        const RadioOptionCard(
          title: 'Log In With HoYoLAB',
          subtitle: 'Sign in on the HoYoLAB page inside the app.',
          icon: LucideIcons.logIn,
          highlightIcon: true,
          badge: AppBadge(label: 'Recommended'),
          selected: true,
          onTap: _noop,
        ),
        const SizedBox(height: 12),
        const RadioOptionCard(
          title: 'Paste Cookie',
          subtitle: 'Copy the cookie from a browser.',
          icon: LucideIcons.cookie,
          selected: false,
          onTap: _noop,
        ),
      ],
    );
  }
}

void main() {
  for (final dark in [false, true]) {
    final name = dark ? 'dark' : 'light';
    testWidgets('components A sheet ($name)', (tester) async {
      tester.view
        ..physicalSize = const Size(390, 1180)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          home: const Scaffold(body: _Sheet()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(_Sheet),
        matchesGoldenFile('components_a_$name.png'),
      );
    });
  }
}
