import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/core/design_system/components/app_toggle.dart';
import 'package:hoyo_aio/core/design_system/components/settings_row.dart';
import 'package:hoyo_aio/core/design_system/components/time_pill.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/game_labels.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/checkin/data/check_in_history_repository_impl.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_record.dart';
import 'package:hoyo_aio/features/checkin/presentation/providers/check_in_provider.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:material_ui/material_ui.dart';

class AutoCheckInSection extends ConsumerWidget {
  const AutoCheckInSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(autoCheckInSettingsProvider).value;
    final games = ref.watch(checkInGamesProvider);
    if (settings == null || games.isEmpty) return const SizedBox.shrink();
    ref.watch(clockTickProvider);
    final now = ref.watch(clockProvider)();
    final repository = ref.read(checkInHistoryRepositoryProvider);
    return SettingsCard(
      children: [
        for (final game in games)
          _GameRow(
            game: game,
            enabled: settings.games.contains(game),
            nextRun: settings.nextRunAfter(now),
            now: now,
            onChanged: (enabled) =>
                unawaited(repository.setGameEnabled(game, enabled: enabled)),
          ),
        _RunTimeRow(
          settings: settings,
          onPicked: (minutes) => unawaited(repository.setRunAtMinutes(minutes)),
        ),
      ],
    );
  }
}

class _GameRow extends StatelessWidget {
  const _GameRow({
    required this.game,
    required this.enabled,
    required this.nextRun,
    required this.now,
    required this.onChanged,
  });

  static const double _dot = 8;

  final Game game;
  final bool enabled;
  final DateTime nextRun;
  final DateTime now;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final time = l10n.clockTime(nextRun);
    final subtitle = !enabled
        ? l10n.checkInAutoOff
        : DateUtils.isSameDay(nextRun, now)
        ? l10n.checkInNextRunToday(time)
        : l10n.checkInNextRunTomorrow(time);
    return _Row(
      leading: Container(
        width: _dot,
        height: _dot,
        decoration: BoxDecoration(
          color: context.gameAccent(game).acc,
          shape: BoxShape.circle,
        ),
      ),
      title: l10n.gameName(game),
      subtitle: subtitle,
      trailing: AppToggle(
        value: enabled,
        onChanged: onChanged,
        semanticLabel: l10n.checkInAutoToggleSemantics(l10n.gameName(game)),
      ),
      subtitleColor: colors.text2,
    );
  }
}

class _RunTimeRow extends StatelessWidget {
  const _RunTimeRow({required this.settings, required this.onPicked});

  final AutoCheckInSettings settings;
  final ValueChanged<int> onPicked;

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.runAtMinutes ~/ TimeOfDay.minutesPerHour,
        minute: settings.runAtMinutes % TimeOfDay.minutesPerHour,
      ),
    );
    if (picked == null) return;
    onPicked(picked.hour * TimeOfDay.minutesPerHour + picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = l10n.clockTime(
      DateTime(0).add(Duration(minutes: settings.runAtMinutes)),
    );
    return _Row(
      title: l10n.checkInRunTime,
      subtitle: l10n.checkInRunTimeHint,
      subtitleColor: context.colors.text2,
      trailing: TimePill(
        label: label,
        semanticLabel: l10n.checkInRunTimeSemantics(label),
        onTap: () => unawaited(_pick(context)),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    required this.trailing,
    this.leading,
  });

  static const double _minHeight = 64;

  final Widget? leading;
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: _minHeight),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      child: Row(
        spacing: AppSpacing.s12,
        children: [
          ?leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.rowTitle.copyWith(
                    color: context.colors.text,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.tabular(AppTextStyles.rowSubtitle)
                      .copyWith(color: subtitleColor),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    ),
  );
}
