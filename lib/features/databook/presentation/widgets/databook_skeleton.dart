import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/components/skeleton.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

class DatabookSkeleton extends StatelessWidget {
  const DatabookSkeleton({super.key});

  static const double _cellHeight = 64;
  static const double _avatar = 42;
  static const double _rowHeight = 64;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget block(double height, {double radius = AppRadius.input}) => Container(
      height: height,
      decoration: BoxDecoration(
        color: colors.surface3,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    return Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.s12,
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.s12),
            child: Column(
              spacing: AppSpacing.s8,
              children: [
                for (var row = 0; row < 2; row++)
                  Row(
                    spacing: AppSpacing.s8,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Expanded(child: block(_cellHeight)),
                    ],
                  ),
              ],
            ),
          ),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.s12,
              children: [
                block(28),
                Row(
                  spacing: AppSpacing.s8,
                  children: [
                    for (var i = 0; i < 6; i++)
                      Container(
                        width: _avatar,
                        height: _avatar,
                        decoration: BoxDecoration(
                          color: colors.surface3,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          for (var i = 0; i < 2; i++)
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: block(_rowHeight),
            ),
        ],
      ),
    );
  }
}
