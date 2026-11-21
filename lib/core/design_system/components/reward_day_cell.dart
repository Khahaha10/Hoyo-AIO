import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_motion.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

enum RewardDayState { claimed, today, missed, upcoming }

class RewardDayCell extends StatefulWidget {
  const RewardDayCell({
    required this.day,
    required this.icon,
    required this.quantity,
    required this.state,
    required this.missedLabel,
    required this.semanticLabel,
    super.key,
  });

  static const cellKey = ValueKey('reward-day-cell');
  static const checkKey = ValueKey('reward-day-check');
  static const dashedKey = ValueKey('reward-day-dashed');
  static const scaleKey = ValueKey('reward-day-scale');
  static const _claimDuration = Duration(milliseconds: 420);

  final int day;
  final IconData icon;
  final String quantity;
  final RewardDayState state;
  final String missedLabel;
  final String semanticLabel;

  @override
  State<RewardDayCell> createState() => _RewardDayCellState();
}

class _RewardDayCellState extends State<RewardDayCell>
    with TickerProviderStateMixin {
  late final _bounce = AnimationController(
    vsync: this,
    duration: RewardDayCell._claimDuration,
    value: 1,
  );
  late final _check = AnimationController(
    vsync: this,
    duration: AppDurations.checkDraw,
    value: 1,
  );
  late final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 0.94), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.04), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 1.04, end: 1), weight: 2),
  ]).animate(CurvedAnimation(parent: _bounce, curve: Curves.easeOut));

  @override
  void didUpdateWidget(RewardDayCell old) {
    super.didUpdateWidget(old);
    final claimedNow =
        old.state != RewardDayState.claimed &&
        widget.state == RewardDayState.claimed;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (claimedNow && !reduceMotion) {
      _bounce.forward(from: 0);
      _check.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    _check.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          key: RewardDayCell.scaleKey,
          scale: _scale.value,
          child: child,
        ),
        child: _cell(context),
      ),
    );
  }

  Widget _cell(BuildContext context) {
    final colors = context.colors;
    final state = widget.state;
    final isToday = state == RewardDayState.today;
    final foreground = switch (state) {
      RewardDayState.today => BrandColors.ink,
      RewardDayState.claimed || RewardDayState.missed => colors.text3,
      RewardDayState.upcoming => colors.text,
    };
    final content = Container(
      key: RewardDayCell.cellKey,
      decoration: BoxDecoration(
        color: switch (state) {
          RewardDayState.today => BrandColors.lime,
          RewardDayState.claimed => colors.surface2,
          RewardDayState.missed => null,
          RewardDayState.upcoming => colors.surface,
        },
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: state == RewardDayState.missed
            ? null
            : Border.all(color: isToday ? BrandColors.lime : colors.border),
        boxShadow: isToday
            ? [
                const BoxShadow(color: BrandColors.lime, spreadRadius: 5),
                BoxShadow(color: colors.bg, spreadRadius: 3),
              ]
            : null,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 6,
            child: Text(
              '${widget.day}',
              style: AppTextStyles.tabular(AppTextStyles.badge).copyWith(
                fontSize: 10,
                height: 12 / 10,
                color: isToday ? BrandColors.ink : colors.text3,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 12, 2, 2),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 1,
                  children: [
                    AppIcon(
                      widget.icon,
                      size: AppIconSize.badge,
                      color: foreground,
                    ),
                    Text(
                      state == RewardDayState.missed
                          ? widget.missedLabel
                          : widget.quantity,
                      style: AppTextStyles.tabular(AppTextStyles.badge)
                          .copyWith(
                            fontSize: 10,
                            height: 12 / 10,
                            fontWeight: FontWeight.w700,
                            color: foreground,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (state == RewardDayState.claimed)
            Positioned(
              key: RewardDayCell.checkKey,
              top: 3,
              right: 3,
              child: ScaleTransition(
                scale: _check,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colors.success,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.check,
                    size: 9,
                    color: colors.surface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    final square = AspectRatio(aspectRatio: 1, child: content);
    if (state != RewardDayState.missed) return square;
    return CustomPaint(
      key: RewardDayCell.dashedKey,
      foregroundPainter: _DashedBorderPainter(color: colors.border2),
      child: square,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  static const double _dash = 4;
  static const double _gap = 3;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.5),
          const Radius.circular(AppRadius.input),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
