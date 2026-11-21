import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_motion.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:material_ui/material_ui.dart';

class PageDots extends StatelessWidget {
  const PageDots({required this.count, required this.index, super.key});

  static const double _dot = 8;
  static const double _activeWidth = 24;
  static const double _gap = 6;

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: _gap,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: reduceMotion ? Duration.zero : AppDurations.gameSwitch,
              width: i == index ? _activeWidth : _dot,
              height: _dot,
              decoration: BoxDecoration(
                color: i == index ? colors.text : colors.border2,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
        ],
      ),
    );
  }
}
