import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/components/skeleton.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

class WarpStatsSkeleton extends StatelessWidget {
  const WarpStatsSkeleton({super.key});

  static const double _heroHeight = 224;
  static const double _statHeight = 76;
  static const double _rowHeight = 52;
  static const int _rows = 3;

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
        spacing: AppSpacing.cardGap,
        children: [
          block(_heroHeight, radius: AppRadius.hero),
          Row(
            spacing: AppSpacing.s8,
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(child: block(_statHeight, radius: AppRadius.tile)),
            ],
          ),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              spacing: AppSpacing.s12,
              children: [for (var i = 0; i < _rows; i++) block(_rowHeight)],
            ),
          ),
        ],
      ),
    );
  }
}
