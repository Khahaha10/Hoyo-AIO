import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_motion.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:material_ui/material_ui.dart';

class AppToggle extends StatefulWidget {
  const AppToggle({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    super.key,
  });

  static const trackKey = ValueKey('app-toggle-track');
  static const double _width = 52;
  static const double _height = 32;
  static const double _border = 2;
  static const double _hitHeight = 44;
  static const double _disabledOpacity = 0.5;

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  @override
  State<AppToggle> createState() => _AppToggleState();
}

class _AppToggleState extends State<AppToggle> {
  var _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = widget.onChanged != null;
    final on = widget.value;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final duration = reduceMotion ? Duration.zero : AppDurations.toggle;
    final knob = _KnobGeometry.of(on: on, pressed: _pressed);
    return Semantics(
      toggled: on,
      enabled: enabled,
      label: widget.semanticLabel,
      onTap: enabled ? () => widget.onChanged!(!on) : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTap: enabled ? () => widget.onChanged!(!on) : null,
        child: Opacity(
          opacity: enabled ? 1 : AppToggle._disabledOpacity,
          child: SizedBox(
            width: AppToggle._width,
            height: AppToggle._hitHeight,
            child: Center(
              child: AnimatedContainer(
                key: AppToggle.trackKey,
                duration: duration,
                curve: AppCurves.toggle,
                width: AppToggle._width,
                height: AppToggle._height,
                decoration: BoxDecoration(
                  color: on ? BrandColors.lime : colors.surface3,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: on ? BrandColors.lime : colors.border2,
                    width: AppToggle._border,
                  ),
                ),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: duration,
                      curve: AppCurves.toggle,
                      left: knob.left,
                      top: knob.top,
                      width: knob.width,
                      height: knob.height,
                      child: AnimatedContainer(
                        duration: duration,
                        decoration: BoxDecoration(
                          color: on ? BrandColors.ink : colors.text3,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KnobGeometry {
  const _KnobGeometry(this.left, this.top, this.width, this.height);

  factory _KnobGeometry.of({required bool on, required bool pressed}) {
    if (pressed) {
      return on
          ? const _KnobGeometry(18, 2, 28, 24)
          : const _KnobGeometry(2, 2, 28, 24);
    }
    return on
        ? const _KnobGeometry(22, 2, 24, 24)
        : const _KnobGeometry(6, 6, 16, 16);
  }

  final double left;
  final double top;
  final double width;
  final double height;
}
