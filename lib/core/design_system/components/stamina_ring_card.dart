import 'dart:math' as math;

import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_motion.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:material_ui/material_ui.dart';

class StaminaRingCard extends StatelessWidget {
  const StaminaRingCard({
    required this.game,
    required this.current,
    required this.max,
    required this.label,
    required this.primaryText,
    required this.secondaryText,
    this.badgeLabel,
    this.badgeVariant = AppBadgeVariant.neutral,
    this.isStale = false,
    super.key,
  });

  static const ringKey = ValueKey('stamina-ring');
  static const double ringSize = 132;
  static const double _staleOpacity = 0.5;

  final Game game;
  final int current;
  final int max;
  final String label;
  final String primaryText;
  final String secondaryText;
  final String? badgeLabel;
  final AppBadgeVariant badgeVariant;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final fraction = max <= 0 ? 0.0 : current / max;
    return Semantics(
      label: '$label, $current / $max. $primaryText. $secondaryText',
      excludeSemantics: true,
      child: AppCard(
        radius: AppRadius.hero,
        padding: const EdgeInsets.all(AppSpacing.s20),
        child: Row(
          spacing: AppSpacing.s20,
          children: [
            Opacity(
              opacity: isStale ? _staleOpacity : 1,
              child: _Ring(
                fraction: fraction,
                current: current,
                max: max,
                fill: isStale ? colors.text3 : context.gameAccent(game).acc,
                reduceMotion: reduceMotion,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.s4,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: AppTextStyles.overline.copyWith(color: colors.text3),
                  ),
                  Text(
                    primaryText,
                    style: AppTextStyles.titleL.copyWith(
                      fontSize: 20,
                      height: 26 / 20,
                      color: colors.text,
                    ),
                  ),
                  Text(
                    secondaryText,
                    style: AppTextStyles.rowSubtitle.copyWith(
                      fontSize: 14,
                      height: 20 / 14,
                      color: colors.text2,
                    ),
                  ),
                  if (badgeLabel != null) ...[
                    const SizedBox(height: AppSpacing.s4),
                    AppBadge(label: badgeLabel!, variant: badgeVariant),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({
    required this.fraction,
    required this.current,
    required this.max,
    required this.fill,
    required this.reduceMotion,
  });

  final double fraction;
  final int current;
  final int max;
  final Color fill;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox.square(
      dimension: StaminaRingCard.ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction),
            duration: reduceMotion ? Duration.zero : AppDurations.ringFill,
            curve: AppCurves.emphasizedDecelerate,
            builder: (context, value, _) => CustomPaint(
              key: StaminaRingCard.ringKey,
              size: const Size.square(StaminaRingCard.ringSize),
              painter: StaminaRingPainter(
                fraction: value,
                track: colors.surface3,
                fill: fill,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: current.toDouble()),
                duration: reduceMotion ? Duration.zero : AppDurations.countUp,
                curve: AppCurves.countUp,
                builder: (context, value, _) => Text(
                  '${value.round()}',
                  style: AppTextStyles.tabular(AppTextStyles.display)
                      .copyWith(color: colors.text),
                ),
              ),
              Text(
                '/ $max',
                style: AppTextStyles.tabular(AppTextStyles.label)
                    .copyWith(fontWeight: FontWeight.w500, color: colors.text3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StaminaRingPainter extends CustomPainter {
  const StaminaRingPainter({
    required this.fraction,
    required this.track,
    required this.fill,
  });

  static const startAngle = -math.pi / 2;
  static const double strokeWidth = 12;

  final double fraction;
  final Color track;
  final Color fill;

  double get sweepAngle => 2 * math.pi * fraction.clamp(0, 1);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - strokeWidth) / 2,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, stroke..color = track);
    if (sweepAngle > 0) {
      canvas.drawArc(rect, startAngle, sweepAngle, false, stroke..color = fill);
    }
  }

  @override
  bool shouldRepaint(StaminaRingPainter old) =>
      old.fraction != fraction || old.track != track || old.fill != fill;
}
