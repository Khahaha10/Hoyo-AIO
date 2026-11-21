import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, this.detail, super.key});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.s8,
          children: [
            Text(
              title,
              style: AppTextStyles.headline.copyWith(color: colors.text),
            ),
            Text(
              context.l10n.placeholderComingSoon,
              style: AppTextStyles.bodyM.copyWith(color: colors.text2),
            ),
            if (detail != null)
              Text(
                detail!,
                style: AppTextStyles.caption.copyWith(color: colors.text3),
              ),
          ],
        ),
      ),
    );
  }
}
