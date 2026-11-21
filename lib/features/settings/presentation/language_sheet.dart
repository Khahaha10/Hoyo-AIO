import 'package:hoyo_aio/core/design_system/components/settings_row.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

const _languageCodes = <String?>[null, 'en', 'id'];

Future<void> showLanguageSheet(
  BuildContext context, {
  required String? current,
  required ValueChanged<String?> onSelect,
}) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: context.colors.surface,
  barrierColor: context.colors.scrim,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.dialog)),
  ),
  builder: (sheetContext) {
    final colors = sheetContext.colors;
    final l10n = sheetContext.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.s16,
          children: [
            Text(
              l10n.settingsLanguage,
              style: AppTextStyles.screenTitle.copyWith(color: colors.text),
            ),
            SettingsCard(
              children: [
                for (final code in _languageCodes)
                  SettingsRow(
                    icon: LucideIcons.globe,
                    title: l10n.settingsLanguageName(code ?? 'system'),
                    trailing: code == current
                        ? AppIcon(LucideIcons.check, color: colors.text)
                        : null,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onSelect(code);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  },
);
