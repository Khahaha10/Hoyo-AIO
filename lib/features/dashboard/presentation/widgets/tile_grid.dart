import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

class TileGrid extends StatelessWidget {
  const TileGrid({required this.tiles, required this.isStale, super.key});

  static const int _columns = 2;
  static const double _staleOpacity = 0.6;

  final List<Widget> tiles;
  final bool isStale;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: isStale ? _staleOpacity : 1,
    child: Column(
      spacing: AppSpacing.s12,
      children: [
        for (var start = 0; start < tiles.length; start += _columns)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.s12,
              children: [
                for (var i = start; i < start + _columns; i++)
                  Expanded(
                    child: i < tiles.length ? tiles[i] : const SizedBox(),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}
