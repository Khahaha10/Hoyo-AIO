import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_motion.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:material_ui/material_ui.dart';

const double _snackbarRadius = 16;
const double _actionHeight = 36;

void showAppSnackbar(
  BuildContext context, {
  required String message,
  required IconData icon,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final colors = context.colors;
  final messenger = ScaffoldMessenger.of(context);
  final hasAction = actionLabel != null && onAction != null;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          0,
          AppSpacing.gutter,
          AppSpacing.s16,
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.s16,
          hasAction ? AppSpacing.s8 : AppSpacing.s12,
          hasAction ? AppSpacing.s8 : AppSpacing.s12,
          hasAction ? AppSpacing.s8 : AppSpacing.s12,
        ),
        elevation: 0,
        backgroundColor: colors.inverse,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_snackbarRadius),
        ),
        duration: hasAction
            ? AppDurations.snackbarWithAction
            : AppDurations.snackbar,
        content: Row(
          spacing: AppSpacing.s12,
          children: [
            AppIcon(icon, color: colors.onInverse),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.chip.copyWith(color: colors.onInverse),
              ),
            ),
            if (hasAction)
              Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  },
                  child: Container(
                    height: _actionHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      actionLabel,
                      style: AppTextStyles.chip.copyWith(
                        fontWeight: FontWeight.w700,
                        color: BrandColors.lime,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
}
