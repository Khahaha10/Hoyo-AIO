import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/components/app_toggle.dart';
import 'package:hoyo_aio/core/design_system/components/expedition_tile.dart';
import 'package:hoyo_aio/core/design_system/components/reward_day_cell.dart';
import 'package:hoyo_aio/core/design_system/components/settings_row.dart';
import 'package:hoyo_aio/core/design_system/components/stamina_ring_card.dart';
import 'package:hoyo_aio/core/design_system/components/stat_tile.dart';
import 'package:hoyo_aio/core/design_system/components/time_pill.dart';
import 'package:hoyo_aio/core/design_system/gallery/gallery_section.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class CardsDemo extends StatefulWidget {
  const CardsDemo({super.key});

  @override
  State<CardsDemo> createState() => _CardsDemoState();
}

class _CardsDemoState extends State<CardsDemo> {
  var _resin = 142;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpacing.cardGap,
    children: [
      StaminaRingCard(
        game: Game.genshin,
        current: _resin,
        max: 200,
        label: 'Original Resin',
        primaryText: 'Full in 3h 12m',
        secondaryText: 'at 21:40 today',
        badgeLabel: '+1 every 8 min',
      ),
      AppButton(
        label: 'Simulate refresh (+20)',
        variant: AppButtonVariant.secondary,
        size: AppButtonSize.small,
        onPressed: () => setState(() => _resin = (_resin + 20) % 201),
      ),
      const StaminaRingCard(
        game: Game.genshin,
        current: 126,
        max: 200,
        label: 'Original Resin',
        primaryText: 'About 142 now',
        secondaryText: 'Estimated from 18:06',
        badgeLabel: 'Stale',
        badgeVariant: AppBadgeVariant.warning,
        isStale: true,
      ),
      const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.cardGap,
        children: [
          Expanded(
            child: StatTile(
              game: Game.starRail,
              icon: LucideIcons.dumbbell,
              label: 'Daily Training',
              value: '400',
              suffix: '/500',
              progress: 0.8,
              note: 'Resets 04:00',
            ),
          ),
          Expanded(
            child: StatTile(
              game: Game.zzz,
              icon: LucideIcons.ticket,
              label: 'Scratch Card',
              value: 'Done',
            ),
          ),
        ],
      ),
      const AppCard(
        child: Column(
          children: [
            ExpeditionTile(
              game: Game.starRail,
              name: 'Himeko',
              subtitle: 'Assignment',
              trailingText: '',
              isDone: true,
              doneLabel: 'Done',
            ),
            ExpeditionTile(
              game: Game.starRail,
              name: 'Asta',
              subtitle: 'Assignment',
              trailingText: '3h 40m',
              isDone: false,
              doneLabel: 'Done',
            ),
          ],
        ),
      ),
    ],
  );
}

class RewardCellsDemo extends StatefulWidget {
  const RewardCellsDemo({super.key});

  @override
  State<RewardCellsDemo> createState() => _RewardCellsDemoState();
}

class _RewardCellsDemoState extends State<RewardCellsDemo> {
  var _claimed = false;

  @override
  Widget build(BuildContext context) {
    final cells = [
      (18, RewardDayState.claimed, LucideIcons.gem, '×20'),
      (11, RewardDayState.missed, LucideIcons.gem, '×20'),
      (
        20,
        _claimed ? RewardDayState.claimed : RewardDayState.today,
        LucideIcons.gem,
        '×20',
      ),
      (21, RewardDayState.upcoming, LucideIcons.gift, '×40'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.s16,
      children: [
        const GalleryLabel('Claimed · missed · today · upcoming'),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Row(
            spacing: AppSpacing.s8,
            children: [
              for (final (day, state, icon, qty) in cells)
                Expanded(
                  child: RewardDayCell(
                    day: day,
                    icon: icon,
                    quantity: qty,
                    state: state,
                    missedLabel: 'Missed',
                    semanticLabel: 'Day $day',
                  ),
                ),
            ],
          ),
        ),
        AppButton(
          label: _claimed ? 'Reset' : 'Claim today',
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.small,
          onPressed: () => setState(() => _claimed = !_claimed),
        ),
      ],
    );
  }
}

class SettingsDemo extends StatefulWidget {
  const SettingsDemo({super.key});

  @override
  State<SettingsDemo> createState() => _SettingsDemoState();
}

class _SettingsDemoState extends State<SettingsDemo> {
  var _reminder = true;

  @override
  Widget build(BuildContext context) => SettingsCard(
    children: [
      SettingsRow(
        icon: LucideIcons.languages,
        title: 'Language',
        value: 'English',
        onTap: () {},
      ),
      SettingsRow(
        icon: LucideIcons.listChecks,
        title: 'Dailies Reminder',
        subtitle: 'If tasks are unfinished',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.s8,
          children: [
            TimePill(
              label: '21:00',
              semanticLabel: 'Reminder time 21:00',
              onTap: () {},
            ),
            AppToggle(
              value: _reminder,
              onChanged: (v) => setState(() => _reminder = v),
              semanticLabel: 'Dailies reminder',
            ),
          ],
        ),
      ),
      const SettingsRow(
        icon: LucideIcons.cookie,
        title: 'Cookie Expired',
        subtitle: 'Always on',
        trailing: AppToggle(
          value: true,
          onChanged: null,
          semanticLabel: 'Cookie expired alerts',
        ),
      ),
    ],
  );
}
