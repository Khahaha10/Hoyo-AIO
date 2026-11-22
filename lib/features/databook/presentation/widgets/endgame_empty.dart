import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';
import 'package:hoyo_aio/features/databook/presentation/databook_format.dart';
import 'package:material_ui/material_ui.dart';

class EndgameEmpty extends StatelessWidget {
  const EndgameEmpty({
    required this.summary,
    required this.now,
    required this.previous,
    this.onViewPrevious,
    super.key,
  });

  static const double _icon = 72;

  final EndgameSummary summary;
  final DateTime now;
  final bool previous;
  final VoidCallback? onViewPrevious;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final accent = context.gameAccent(summary.mode.game);
    final left = previous ? null : summary.timeLeft(now);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s40),
      child: Column(
        spacing: AppSpacing.s12,
        children: [
          Container(
            width: _icon,
            height: _icon,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.soft,
            ),
            child: AppIcon(endgameIcon(summary.mode), color: accent.accInk),
          ),
          Text(
            previous
                ? l10n.databookNotAttemptedPrevious
                : l10n.databookNotAttempted,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleM.copyWith(color: colors.text),
          ),
          if (!previous)
            Text(
              left == null
                  ? l10n.databookEmptyEnded
                  : l10n.databookEmptyLeft(l10n.duration(left)),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyM.copyWith(color: colors.text2),
            ),
          if (!previous && onViewPrevious != null)
            AppButton(
              label: l10n.databookViewPrevious,
              onPressed: onViewPrevious,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.small,
              expand: false,
            ),
        ],
      ),
    );
  }
}
