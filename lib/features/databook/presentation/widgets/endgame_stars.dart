import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class EndgameStars extends StatelessWidget {
  const EndgameStars({required this.stars, required this.maxStars, super.key});

  static const double _size = 14;

  final int stars;
  final int maxStars;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: '$stars / $maxStars',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < maxStars; i++)
            Icon(
              LucideIcons.star,
              size: _size,
              color: i < stars ? colors.warning : colors.text3,
            ),
        ],
      ),
    );
  }
}
