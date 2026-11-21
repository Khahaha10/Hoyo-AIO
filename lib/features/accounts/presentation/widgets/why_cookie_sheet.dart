import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/info_banner.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

Future<void> showWhyCookieSheet(BuildContext context) =>
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
      builder: (_) => const _WhyCookieSheet(),
    );

class _WhyCookieSheet extends StatelessWidget {
  const _WhyCookieSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.s16,
          children: [
            Text(
              l10n.whyCookieTitle,
              style: AppTextStyles.titleL.copyWith(color: colors.text),
            ),
            Text(
              l10n.whyCookieBody,
              style: AppTextStyles.bodyM.copyWith(color: colors.text2),
            ),
            InfoBanner(
              icon: LucideIcons.shieldCheck,
              message: l10n.whyCookieSafety,
            ),
            AppButton(
              label: l10n.whyCookieClose,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
