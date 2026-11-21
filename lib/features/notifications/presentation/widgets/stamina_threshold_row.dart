import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/core/design_system/components/app_slider.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/selected_role_provider.dart';
import 'package:hoyo_aio/features/dashboard/presentation/providers/notes_provider.dart';
import 'package:material_ui/material_ui.dart';

class StaminaThresholdRow extends ConsumerWidget {
  const StaminaThresholdRow({
    required this.percent,
    required this.onChanged,
    super.key,
  });

  static const int minPercent = 50;
  static const int maxPercent = 100;
  static const int _step = 5;
  static const int _midPercent = 75;
  static const double _leftInset = 66;

  final int percent;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final role = ref.watch(selectedRoleProvider);
    final stamina = role == null
        ? null
        : ref.watch(notesProvider(role)).value?.note.stamina;
    final value = stamina == null
        ? l10n.notificationsThresholdPercent(percent)
        : l10n.notificationsThresholdValue(
            percent,
            (stamina.max * percent / maxPercent).ceil(),
            stamina.max,
            _staminaName(role?.game, l10n),
          );
    final tickStyle = AppTextStyles.tabular(AppTextStyles.caption)
        .copyWith(color: colors.text3);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _leftInset,
        0,
        AppSpacing.s16,
        AppSpacing.s12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.notificationsNotifyAt,
                  style: AppTextStyles.rowSubtitle.copyWith(
                    color: colors.text2,
                  ),
                ),
              ),
              Text(
                value,
                style: AppTextStyles.tabular(AppTextStyles.label)
                    .copyWith(color: colors.text),
              ),
            ],
          ),
          AppSlider(
            value: percent.toDouble(),
            min: minPercent.toDouble(),
            max: maxPercent.toDouble(),
            divisions: (maxPercent - minPercent) ~/ _step,
            semanticLabel: l10n.notificationsNotifyAt,
            onChanged: onChanged == null
                ? null
                : (next) {
                    final rounded = next.round();
                    if (rounded != percent) onChanged?.call(rounded);
                  },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final tick in [minPercent, _midPercent, maxPercent])
                Text(
                  l10n.notificationsThresholdPercent(tick),
                  style: tickStyle,
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _staminaName(Game? game, AppLocalizations l10n) =>
      switch (game) {
        Game.genshin => l10n.genshinResin,
        Game.starRail => l10n.starRailTrailblazePower,
        Game.zzz => l10n.zzzBattery,
        Game.hi3 || null => '',
      };
}
