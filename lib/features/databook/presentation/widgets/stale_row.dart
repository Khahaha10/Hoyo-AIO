import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class StaleRow extends StatelessWidget {
  const StaleRow({required this.fetchedAt, required this.onRetry, super.key});

  final DateTime? fetchedAt;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final at = fetchedAt;
    return Semantics(
      liveRegion: true,
      container: true,
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        child: Row(
          spacing: AppSpacing.s12,
          children: [
            AppIcon(LucideIcons.wifiOff, color: colors.text2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.s8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        l10n.databookCouldntRefresh,
                        style: AppTextStyles.rowTitle.copyWith(
                          color: colors.text,
                        ),
                      ),
                      AppBadge(
                        label: l10n.dashboardStale,
                        variant: AppBadgeVariant.warning,
                      ),
                    ],
                  ),
                  if (at != null)
                    Text(
                      l10n.databookShowingFrom(l10n.clockTime(at)),
                      style: AppTextStyles.caption.copyWith(
                        color: colors.text2,
                      ),
                    ),
                ],
              ),
            ),
            AppButton(
              label: l10n.commonRetry,
              variant: AppButtonVariant.text,
              size: AppButtonSize.small,
              expand: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
