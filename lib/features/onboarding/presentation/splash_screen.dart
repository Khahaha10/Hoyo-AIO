import 'package:hoyo_aio/core/design_system/components/app_mark.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const double _progressWidth = 120;
  static const double _progressHeight = 4;
  static const _progressDuration = Duration(milliseconds: 1200);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const Spacer(),
              const AppMark(),
              const SizedBox(height: AppSpacing.s20),
              Text(
                l10n.appName,
                style: AppTextStyles.headline.copyWith(
                  fontSize: 32,
                  height: 40 / 32,
                  fontWeight: FontWeight.w800,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                l10n.splashTagline,
                style: AppTextStyles.bodyM.copyWith(color: colors.text2),
              ),
              const Spacer(),
              SizedBox(
                width: _progressWidth,
                height: _progressHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: reduceMotion ? 0.9 : 0, end: 0.9),
                    duration: reduceMotion ? Duration.zero : _progressDuration,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: _progressHeight,
                      color: colors.text,
                      backgroundColor: colors.surface3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              Text(
                '${l10n.splashDisclaimerUnofficial}\n'
                '${l10n.splashDisclaimerNotAffiliated}',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(color: colors.text3),
              ),
              const SizedBox(height: AppSpacing.s40),
            ],
          ),
        ),
      ),
    );
  }
}
