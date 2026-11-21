import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/onboarding/presentation/onboarding_controller.dart';
import 'package:hoyo_aio/features/onboarding/presentation/widgets/onboarding_illustrations.dart';
import 'package:hoyo_aio/features/onboarding/presentation/widgets/page_dots.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _pageCount = 3;
  static const double _nextWidth = 140;
  static const double _illustrationMaxHeight = 392;
  static const _pageCurve = Curves.easeOutCubic;
  static const _pageDuration = Duration(milliseconds: 300);

  final _controller = PageController();
  var _index = 0;
  var _finishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await ref.read(onboardingControllerProvider.notifier).complete();
  }

  void _next() {
    if (_index == _pageCount - 1) {
      _finish();
      return;
    }
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.jumpToPage(_index + 1);
    } else {
      _controller.nextPage(duration: _pageDuration, curve: _pageCurve);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final pages = [
      (
        l10n.onboardingNotesTitle,
        l10n.onboardingNotesBody,
        const NotesIllustration(),
      ),
      (
        l10n.onboardingWidgetsTitle,
        l10n.onboardingWidgetsBody,
        const WidgetsIllustration(),
      ),
      (
        l10n.onboardingCheckInTitle,
        l10n.onboardingCheckInBody,
        const CheckInIllustration(),
      ),
    ];
    final isLast = _index == _pageCount - 1;
    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              step: l10n.onboardingStep(_index + 1, _pageCount),
              skipLabel: isLast ? null : l10n.onboardingSkip,
              onSkip: _finish,
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (final (title, body, illustration) in pages)
                    _Page(
                      title: title,
                      body: body,
                      illustration: illustration,
                      maxIllustrationHeight: _illustrationMaxHeight,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.s16,
                AppSpacing.gutter,
                AppSpacing.s24,
              ),
              child: Row(
                children: [
                  PageDots(count: _pageCount, index: _index),
                  const Spacer(),
                  SizedBox(
                    width: isLast ? null : _nextWidth,
                    child: AppButton(
                      label: isLast
                          ? l10n.onboardingGetStarted
                          : l10n.onboardingNext,
                      trailingIcon: isLast ? null : LucideIcons.arrowRight,
                      expand: !isLast,
                      isLoading: _finishing,
                      onPressed: _next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.skipLabel,
    required this.onSkip,
  });

  final String step;
  final String? skipLabel;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.s8,
        AppSpacing.s8,
        AppSpacing.s8,
      ),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Text(
              step.toUpperCase(),
              style: AppTextStyles.overline.copyWith(
                color: context.colors.text3,
              ),
            ),
            const Spacer(),
            if (skipLabel != null)
              AppButton(
                label: skipLabel!,
                variant: AppButtonVariant.text,
                expand: false,
                onPressed: onSkip,
              ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.body,
    required this.illustration,
    required this.maxIllustrationHeight,
  });

  final String title;
  final String body;
  final Widget illustration;
  final double maxIllustrationHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final illustrationHeight = (constraints.maxHeight * 0.58).clamp(
          0.0,
          maxIllustrationHeight,
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Container(
                  height: illustrationHeight,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: colors.surface2,
                    borderRadius: BorderRadius.circular(AppRadius.illustration),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: constraints.maxWidth - AppSpacing.gutter * 2,
                      height: maxIllustrationHeight,
                      child: illustration,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s32),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: AppTextStyles.headline.copyWith(color: colors.text),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(
                body,
                style: AppTextStyles.bodyL.copyWith(color: colors.text2),
              ),
            ],
          ),
        );
      },
    );
  }
}
