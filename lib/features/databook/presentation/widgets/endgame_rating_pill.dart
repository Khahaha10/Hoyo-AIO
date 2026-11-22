import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:material_ui/material_ui.dart';

class EndgameRatingPill extends StatelessWidget {
  const EndgameRatingPill({required this.rating, super.key});

  static const double _size = 28;

  final String rating;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final top = rating == 'S';
    return Semantics(
      label: rating,
      excludeSemantics: true,
      child: Container(
        width: _size,
        height: _size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: top ? BrandColors.lime : colors.surface3,
        ),
        child: Text(
          rating,
          style: AppTextStyles.label.copyWith(
            color: top ? BrandColors.ink : colors.text,
          ),
        ),
      ),
    );
  }
}
