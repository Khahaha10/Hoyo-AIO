import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:material_ui/material_ui.dart';

class AppSlider extends StatelessWidget {
  const AppSlider({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.min = 0,
    this.max = 1,
    this.divisions,
    super.key,
  });

  static const double _trackHeight = 6;
  static const double _thumbRadius = 12;

  final double value;
  final ValueChanged<double>? onChanged;
  final String semanticLabel;
  final double min;
  final double max;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: semanticLabel,
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: _trackHeight,
          activeTrackColor: colors.text,
          inactiveTrackColor: colors.surface3,
          disabledActiveTrackColor: colors.text3,
          disabledInactiveTrackColor: colors.surface3,
          trackShape: const RoundedRectSliderTrackShape(),
          thumbShape: _OutlinedThumbShape(borderColor: colors.text),
          overlayShape: SliderComponentShape.noOverlay,
          tickMarkShape: SliderTickMarkShape.noTickMark,
          showValueIndicator: ShowValueIndicator.never,
          padding: const EdgeInsets.symmetric(horizontal: _thumbRadius),
        ),
        child: Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _OutlinedThumbShape extends SliderComponentShape {
  const _OutlinedThumbShape({required this.borderColor});

  static const double _radius = 12;
  static const double _border = 2;
  static const _fill = Color(0xFFFFFFFF);
  static const _shadow = Color.fromRGBO(16, 24, 40, .2);

  final Color borderColor;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas
      ..drawCircle(
        center.translate(0, 2),
        _radius,
        Paint()
          ..color = _shadow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawCircle(center, _radius, Paint()..color = _fill)
      ..drawCircle(
        center,
        _radius - _border / 2,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = _border,
      );
  }
}
