import 'package:flutter_animate/flutter_animate.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_motion.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:material_ui/material_ui.dart';

class Skeleton extends StatelessWidget {
  const Skeleton({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final placeholder = ExcludeSemantics(child: child);
    if (reduceMotion) return placeholder;
    return placeholder
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: AppDurations.shimmer,
          curve: AppCurves.shimmer,
          color: context.colors.shimmer,
        );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    required this.width,
    required this.height,
    this.radius = AppRadius.code,
    this.isCircle = false,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surface3,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}
