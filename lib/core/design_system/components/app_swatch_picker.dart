import 'dart:math' as math;

import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:material_ui/material_ui.dart';

class SwatchOption<T> {
  const SwatchOption({
    required this.value,
    required this.label,
    required this.colors,
  });

  final T value;
  final String label;
  final List<Color> colors;
}

class AppSwatchPicker<T> extends StatelessWidget {
  const AppSwatchPicker({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.size = 28,
    this.gap = 6,
    this.ringColor,
    super.key,
  });

  static const double _hitHeight = 44;
  static const double _ring = 2;

  final List<SwatchOption<T>> options;
  final T selected;
  final ValueChanged<T>? onChanged;
  final double size;
  final double gap;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in options)
          Semantics(
            inMutuallyExclusiveGroup: true,
            checked: option.value == selected,
            label: option.label,
            onTap: onChanged == null ? null : () => onChanged!(option.value),
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onChanged == null ? null : () => onChanged!(option.value),
              child: SizedBox(
                width: size + gap,
                height: _hitHeight,
                child: Center(
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: option.colors.length == 1
                          ? option.colors.single
                          : null,
                      gradient: option.colors.length > 1
                          ? _conic(option.colors)
                          : null,
                      border: Border.all(
                        color: ringColor ?? colors.surface,
                        width: _ring,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: option.value == selected
                              ? colors.text
                              : colors.border2,
                          spreadRadius: option.value == selected ? 2 : 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static SweepGradient _conic(List<Color> colors) {
    final step = 1 / colors.length;
    return SweepGradient(
      transform: const GradientRotation(-math.pi / 2),
      colors: [
        for (final c in colors) ...[c, c],
      ],
      stops: [
        for (var i = 0; i < colors.length; i++) ...[i * step, (i + 1) * step],
      ],
    );
  }
}
