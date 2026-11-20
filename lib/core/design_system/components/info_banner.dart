import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

enum InfoBannerVariant { info, warning }

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    required this.icon,
    required this.message,
    this.variant = InfoBannerVariant.info,
    super.key,
  });

  final IconData icon;
  final String message;
  final InfoBannerVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isWarning = variant == InfoBannerVariant.warning;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: isWarning ? 14 : AppSpacing.s16,
      ),
      decoration: BoxDecoration(
        color: isWarning ? colors.warningBg : colors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.banner),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s12,
        children: [
          AppIcon(icon, color: isWarning ? colors.warning : colors.text2),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.rowSubtitle.copyWith(
                color: isWarning ? colors.text : colors.text2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
