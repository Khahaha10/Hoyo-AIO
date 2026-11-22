import 'dart:math' as math;

import 'package:hoyo_aio/core/design_system/theme/extensions/game_colors.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:material_ui/material_ui.dart';

class AppMark extends StatelessWidget {
  const AppMark({this.size = 104, this.rounded = true, super.key});

  final double size;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: BrandColors.ink,
        borderRadius: rounded
            ? BorderRadius.circular(AppRadius.illustration * size / 104)
            : null,
        border: rounded ? Border.all(color: context.colors.border) : null,
      ),
      child: AppMarkGlyph(size: size),
    );
  }
}

class AppMarkGlyph extends StatelessWidget {
  const AppMarkGlyph({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(
        arcs: [
          for (final game in const [
            Game.genshin,
            Game.starRail,
            Game.zzz,
            Game.hi3,
          ])
            GameColors.light.of(game).acc,
        ],
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.arcs});

  static const _ringRatio = 0.24;
  static const _strokeRatio = 0.06;
  static const _dotRatio = 0.075;
  static const _gap = math.pi / 14;

  final List<Color> arcs;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(
      center: center,
      radius: size.shortestSide * _ringRatio,
    );
    final sweep = 2 * math.pi / arcs.length;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * _strokeRatio
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < arcs.length; i++) {
      canvas.drawArc(
        rect,
        -math.pi / 2 + i * sweep + _gap / 2,
        sweep - _gap,
        false,
        paint..color = arcs[i],
      );
    }
    canvas.drawCircle(
      center,
      size.shortestSide * _dotRatio,
      Paint()..color = BrandColors.lime,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter old) => false;
}
