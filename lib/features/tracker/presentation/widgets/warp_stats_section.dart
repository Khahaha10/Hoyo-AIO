import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/error/app_exception_l10n.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/tracker/presentation/providers/tracker_providers.dart';
import 'package:hoyo_aio/features/tracker/presentation/widgets/pity_body.dart';
import 'package:hoyo_aio/features/tracker/presentation/widgets/tracker_cards.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class WarpStatsSection extends ConsumerWidget {
  const WarpStatsSection({
    required this.role,
    required this.banner,
    required this.onImport,
    super.key,
  });

  final SavedRole role;
  final String banner;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final stats = ref.watch(warpPityProvider(role, banner));
    return switch (stats) {
      AsyncData(value: final pity?) when pity.total > 0 => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.cardGap,
        children: [
          Row(
            spacing: AppSpacing.s8,
            children: [
              AppIcon(
                LucideIcons.cloud,
                size: AppIconSize.badge,
                color: colors.text3,
              ),
              Expanded(
                child: Text(
                  l10n.trackerWarpSource,
                  style: AppTextStyles.caption.copyWith(color: colors.text3),
                ),
              ),
            ],
          ),
          PityBody(
            game: Game.starRail,
            banner: banner,
            pity: pity,
            showFourStar: false,
          ),
          AppButton(
            label: l10n.trackerImport,
            icon: LucideIcons.clipboardPaste,
            variant: AppButtonVariant.secondary,
            onPressed: onImport,
          ),
        ],
      ),
      AsyncData() => GachaEmptyCard(onImport: onImport),
      AsyncError(:final error) => AppCard(
        padding: const EdgeInsets.all(AppSpacing.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.s12,
          children: [
            Text(
              error is AppException
                  ? error.localizedMessage(l10n)
                  : l10n.trackerWarpFailed,
              style: AppTextStyles.bodyM.copyWith(color: colors.text2),
            ),
            AppButton(
              label: l10n.commonRetry,
              variant: AppButtonVariant.secondary,
              onPressed: () => ref.invalidate(warpPityProvider(role, banner)),
            ),
            AppButton(
              label: l10n.trackerImport,
              icon: LucideIcons.clipboardPaste,
              onPressed: onImport,
            ),
          ],
        ),
      ),
      _ => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.s24),
        child: LinearProgressIndicator(),
      ),
    };
  }
}
