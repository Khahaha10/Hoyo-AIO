import 'package:hoyo_aio/core/design_system/tokens/app_motion.dart';
import 'package:material_ui/material_ui.dart';

class Pressable extends StatefulWidget {
  const Pressable({
    required this.builder,
    required this.onTap,
    this.pressedScale = 0.97,
    super.key,
  });

  final Widget Function(BuildContext context, bool pressed) builder;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  var _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: reduceMotion ? Duration.zero : AppDurations.press,
        child: widget.builder(context, _pressed),
      ),
    );
  }
}
