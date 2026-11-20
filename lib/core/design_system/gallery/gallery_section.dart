import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

class GallerySection extends StatelessWidget {
  const GallerySection({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.s12,
      children: [
        Text(
          title,
          style: AppTextStyles.titleL.copyWith(color: context.colors.text),
        ),
        ...children,
      ],
    );
  }
}

class GalleryLabel extends StatelessWidget {
  const GalleryLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: AppTextStyles.overline.copyWith(color: context.colors.text3),
  );
}
