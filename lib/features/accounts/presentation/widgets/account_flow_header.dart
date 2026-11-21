import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class AccountFlowHeader extends StatelessWidget {
  const AccountFlowHeader({
    required this.title,
    this.subtitle,
    this.large = true,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool large;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canPop = context.canPop();
    final titleStyle = large ? AppTextStyles.headline : AppTextStyles.titleL;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.s8,
        AppSpacing.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s8,
        children: [
          SizedBox(
            height: AppIconButton.size,
            child: Row(
              children: [
                if (canPop)
                  AppIconButton(
                    icon: LucideIcons.chevronLeft,
                    semanticLabel: context.l10n.commonBack,
                    onPressed: context.pop,
                  ),
                const Spacer(),
                ?trailing,
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Semantics(
            header: true,
            child: Text(title, style: titleStyle.copyWith(color: colors.text)),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: AppTextStyles.bodyM.copyWith(color: colors.text2),
            ),
        ],
      ),
    );
  }
}
