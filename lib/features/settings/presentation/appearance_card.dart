import 'dart:async';
import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/app/app_settings_provider.dart';
import 'package:hoyo_aio/core/design_system/components/app_segmented_control.dart';
import 'package:hoyo_aio/core/design_system/components/app_swatch_picker.dart';
import 'package:hoyo_aio/core/design_system/components/app_toggle.dart';
import 'package:hoyo_aio/core/design_system/components/settings_row.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/game_colors.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/settings/presentation/language_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'appearance_card.g.dart';

@riverpod
Future<bool> dynamicColorSupported(Ref ref) async =>
    Platform.isAndroid && await DynamicColorPlugin.getCorePalette() != null;

class AppearanceCard extends ConsumerWidget {
  const AppearanceCard({required this.preferences, super.key});

  final AppPreferences preferences;

  static List<Color> _swatch(AppAccent accent) => switch (accent) {
    AppAccent.match => [
      for (final game in Game.values) GameColors.light.of(game).acc,
    ],
    AppAccent.lime => const [BrandColors.lime],
    AppAccent.neutral => const [AppAccent.neutralColor],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final actions = ref.read(appSettingsActionsProvider.notifier);
    final dynamicSupported =
        ref.watch(dynamicColorSupportedProvider).value ?? false;
    final dynamicOn = dynamicSupported && preferences.dynamicColor;
    final localeCode = preferences.locale?.languageCode;
    return SettingsCard(
      children: [
        SettingsRow(
          icon: LucideIcons.sunMedium,
          title: l10n.settingsTheme,
          trailing: AppSegmentedControl<ThemeMode>(
            options: [
              SegmentOption(
                value: ThemeMode.system,
                label: l10n.widgetThemeSystem,
              ),
              SegmentOption(
                value: ThemeMode.light,
                label: l10n.widgetThemeLight,
              ),
              SegmentOption(value: ThemeMode.dark, label: l10n.widgetThemeDark),
            ],
            selected: preferences.themeMode,
            onChanged: (mode) => unawaited(actions.setThemeMode(mode)),
          ),
        ),
        if (dynamicSupported)
          SettingsRow(
            icon: LucideIcons.wallpaper,
            title: l10n.settingsDynamicColor,
            subtitle: l10n.settingsDynamicColorSubtitle,
            trailing: AppToggle(
              value: preferences.dynamicColor,
              semanticLabel: l10n.settingsDynamicColor,
              onChanged: (enabled) =>
                  unawaited(actions.setDynamicColor(enabled: enabled)),
            ),
          ),
        SettingsRow(
          icon: LucideIcons.droplet,
          title: l10n.settingsAccentColor,
          subtitle: l10n.settingsAccentName(preferences.accent.name),
          trailing: AppSwatchPicker<AppAccent>(
            options: [
              for (final accent in AppAccent.values)
                SwatchOption(
                  value: accent,
                  label: l10n.settingsAccentName(accent.name),
                  colors: _swatch(accent),
                ),
            ],
            selected: preferences.accent,
            onChanged: dynamicOn
                ? null
                : (accent) => unawaited(actions.setAccent(accent)),
          ),
        ),
        SettingsRow(
          icon: LucideIcons.globe,
          title: l10n.settingsLanguage,
          value: l10n.settingsLanguageName(localeCode ?? 'system'),
          onTap: () => showLanguageSheet(
            context,
            current: localeCode,
            onSelect: (code) => unawaited(actions.setLocale(code)),
          ),
        ),
      ],
    );
  }
}
