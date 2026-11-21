import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_mark.dart';
import 'package:hoyo_aio/core/design_system/components/settings_row.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/settings/presentation/providers/package_info_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const double _mark = 72;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final info = ref.watch(packageInfoProvider).value;
    final version = info == null
        ? null
        : l10n.aboutVersion(info.version, info.buildNumber);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.s8,
            AppSpacing.gutter,
            AppSpacing.s24,
          ),
          children: [
            Row(
              spacing: AppSpacing.s12,
              children: [
                if (context.canPop())
                  AppIconButton(
                    icon: LucideIcons.chevronLeft,
                    semanticLabel: l10n.commonBack,
                    onPressed: context.pop,
                  ),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.aboutTitle,
                      style: AppTextStyles.screenTitle.copyWith(
                        color: colors.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
            const Center(child: AppMark(size: _mark)),
            const SizedBox(height: AppSpacing.s12),
            Text(
              l10n.appName,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleL.copyWith(color: colors.text),
            ),
            if (version != null)
              Text(
                version,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyM.copyWith(color: colors.text2),
              ),
            const SizedBox(height: AppSpacing.s24),
            _TextCard(
              title: l10n.aboutDisclaimerTitle,
              body: l10n.aboutDisclaimerBody,
            ),
            const SizedBox(height: AppSpacing.s12),
            _TextCard(
              title: l10n.aboutCreditsTitle,
              body: '${l10n.aboutCreditReference}\n\n${l10n.aboutCreditFont}',
            ),
            const SizedBox(height: AppSpacing.s12),
            SettingsCard(
              children: [
                SettingsRow(
                  icon: LucideIcons.scrollText,
                  title: l10n.aboutLicenses,
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: l10n.appName,
                    applicationVersion: version,
                    applicationIcon: const Padding(
                      padding: EdgeInsets.all(AppSpacing.s16),
                      child: AppMark(size: _mark),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TextCard extends StatelessWidget {
  const _TextCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s8,
        children: [
          Text(title, style: AppTextStyles.titleM.copyWith(color: colors.text)),
          Text(body, style: AppTextStyles.bodyM.copyWith(color: colors.text2)),
        ],
      ),
    );
  }
}
