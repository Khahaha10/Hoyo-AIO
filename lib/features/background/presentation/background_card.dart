import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/app/flavor_provider.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_segmented_control.dart';
import 'package:hoyo_aio/core/design_system/components/settings_row.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/platform/system_settings.dart';
import 'package:hoyo_aio/features/background/data/background_settings_repository_impl.dart';
import 'package:hoyo_aio/features/background/presentation/providers/background_sync_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class BackgroundCard extends ConsumerWidget {
  const BackgroundCard({super.key});

  static const refreshOptions = [15, 30, 60, 120];
  static const double _segmentInset = 66;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final minutes = ref.watch(refreshMinutesProvider).value;
    final batteryIgnored = ref.watch(batteryOptimizationIgnoredProvider).value;
    if (minutes == null) return const SizedBox.shrink();
    return SettingsCard(
      children: [
        Column(
          children: [
            SettingsRow(
              icon: LucideIcons.refreshCw,
              title: l10n.backgroundRefresh,
              subtitle: l10n.backgroundRefreshBody,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _segmentInset,
                0,
                AppSpacing.s16,
                AppSpacing.s12,
              ),
              child: AppSegmentedControl<int>(
                options: [
                  for (final option in refreshOptions)
                    SegmentOption(
                      value: option,
                      label: l10n.backgroundRefreshMinutes(option),
                    ),
                ],
                selected: refreshOptions.contains(minutes)
                    ? minutes
                    : refreshOptions[1],
                onChanged: (value) => unawaited(
                  ref
                      .read(backgroundSettingsRepositoryProvider)
                      .setRefreshMinutes(value),
                ),
              ),
            ),
          ],
        ),
        if (ref.watch(flavorProvider).galleryEnabled)
          SettingsRow(
            icon: LucideIcons.play,
            title: l10n.backgroundRunNow,
            onTap: () async => runRefreshNowInBackground(
              await ref.read(workmanagerProvider.future),
              ref.read(flavorProvider),
            ),
          ),
        if (batteryIgnored == false)
          SettingsRow(
            icon: LucideIcons.batteryWarning,
            title: l10n.backgroundBattery,
            subtitle: l10n.backgroundBatteryBody,
            onTap: () async {
              await showBatterySheet(context, ref);
              ref.invalidate(batteryOptimizationIgnoredProvider);
            },
          ),
      ],
    );
  }
}

Future<void> showBatterySheet(BuildContext context, WidgetRef ref) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.surface,
      barrierColor: context.colors.scrim,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.dialog),
        ),
      ),
      builder: (sheetContext) {
        final colors = sheetContext.colors;
        final l10n = sheetContext.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.s16,
              children: [
                Text(
                  l10n.backgroundBatteryTitle,
                  style: AppTextStyles.titleL.copyWith(color: colors.text),
                ),
                Text(
                  l10n.backgroundBatterySteps,
                  style: AppTextStyles.bodyM.copyWith(color: colors.text2),
                ),
                AppButton(
                  label: l10n.backgroundBatteryOpen,
                  icon: LucideIcons.externalLink,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    unawaited(
                      ref
                          .read(systemSettingsProvider)
                          .openBatteryOptimizationSettings(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
