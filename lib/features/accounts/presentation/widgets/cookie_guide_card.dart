import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

const monospaceFontFamily = 'monospace';

class CookieGuideCard extends StatelessWidget {
  const CookieGuideCard({super.key});

  static const double _stepSize = 24;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final steps = [
      l10n.pasteCookieStep1,
      l10n.pasteCookieStep2,
      l10n.pasteCookieStep3,
      l10n.pasteCookieStep4,
      l10n.pasteCookieStep5,
    ];
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pasteCookieGuideTitle,
            style: AppTextStyles.titleM.copyWith(color: colors.text),
          ),
          const SizedBox(height: AppSpacing.s8),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.s12,
                children: [
                  Container(
                    width: _stepSize,
                    height: _stepSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.surface2,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: AppTextStyles.badge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    ),
                  ),
                  Expanded(child: InlineCodeText(steps[i])),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class InlineCodeText extends StatelessWidget {
  const InlineCodeText(this.text, {super.key});

  static const _codeMark = '`';

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = AppTextStyles.rowSubtitle.copyWith(color: colors.text);
    final parts = text.split(_codeMark);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          for (var i = 0; i < parts.length; i++)
            if (i.isOdd)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface2,
                    borderRadius: BorderRadius.circular(AppRadius.code),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    parts[i],
                    style: base.copyWith(fontFamily: monospaceFontFamily),
                  ),
                ),
              )
            else
              TextSpan(text: parts[i]),
        ],
      ),
    );
  }
}
