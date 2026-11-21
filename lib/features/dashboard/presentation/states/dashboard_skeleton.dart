import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/components/skeleton.dart';
import 'package:hoyo_aio/core/design_system/components/stamina_ring_card.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  static const double _ringStroke = 12;
  static const double _tileHeight = 112;
  static const double _lineHeight = 14;
  static const double _titleHeight = 22;
  static const double _shortLine = 96;
  static const double _longLine = 160;
  static const double _listHeight = 220;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.s12,
        children: [
          AppCard(
            radius: AppRadius.hero,
            padding: const EdgeInsets.all(AppSpacing.s20),
            child: Row(
              spacing: AppSpacing.s20,
              children: [
                Container(
                  width: StaminaRingCard.ringSize,
                  height: StaminaRingCard.ringSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.surface3,
                      width: _ringStroke,
                    ),
                  ),
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.s8,
                    children: [
                      SkeletonBox(width: _shortLine, height: _lineHeight),
                      SkeletonBox(width: _longLine, height: _titleHeight),
                      SkeletonBox(width: _shortLine, height: _lineHeight),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (var row = 0; row < 2; row++)
            const Row(
              spacing: AppSpacing.s12,
              children: [
                Expanded(child: _TileSkeleton()),
                Expanded(child: _TileSkeleton()),
              ],
            ),
          const SkeletonBox(
            width: double.infinity,
            height: _listHeight,
            radius: AppRadius.tile,
          ),
        ],
      ),
    );
  }
}

class _TileSkeleton extends StatelessWidget {
  const _TileSkeleton();

  @override
  Widget build(BuildContext context) => const SkeletonBox(
    width: double.infinity,
    height: DashboardSkeleton._tileHeight,
    radius: AppRadius.tile,
  );
}
