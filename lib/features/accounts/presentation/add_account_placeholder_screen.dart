import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

class AddAccountPlaceholderScreen extends StatelessWidget {
  const AddAccountPlaceholderScreen({required this.showDevTools, super.key});

  final bool showDevTools;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.s12,
            children: [
              const Spacer(),
              Text(
                l10n.addAccountPlaceholderTitle,
                style: AppTextStyles.headline.copyWith(color: colors.text),
              ),
              Text(
                l10n.addAccountPlaceholderBody,
                style: AppTextStyles.bodyL.copyWith(color: colors.text2),
              ),
              const Spacer(),
              AppButton(
                label: l10n.addAccountPlaceholderAction,
                onPressed: null,
              ),
              if (showDevTools) ...[
                AppButton(
                  label: 'Component Gallery',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.push(AppRoutes.gallery),
                ),
                AppButton(
                  label: 'API Debug',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.push(AppRoutes.apiDebug),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
