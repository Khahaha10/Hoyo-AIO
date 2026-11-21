import 'dart:math' as math;

import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/presentation/widgets/why_cookie_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class DashboardEmpty extends StatelessWidget {
  const DashboardEmpty({super.key});

  static const double _sidePadding = 32;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.s24,
              AppSpacing.gutter,
              0,
            ),
            child: Semantics(
              header: true,
              child: Text(
                l10n.navDashboard,
                style: AppTextStyles.titleL.copyWith(color: colors.text),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AppSpacing.s24,
                children: [
                  const _EmptyIllustration(),
                  Column(
                    spacing: AppSpacing.s8,
                    children: [
                      Text(
                        l10n.dashboardEmptyTitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headline.copyWith(
                          color: colors.text,
                        ),
                      ),
                      Text(
                        l10n.dashboardNoRoles,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyM.copyWith(
                          color: colors.text2,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    spacing: AppSpacing.s8,
                    children: [
                      AppButton(
                        label: l10n.addAccountTitle,
                        icon: LucideIcons.plus,
                        onPressed: () => context.push(AppRoutes.addAccount),
                      ),
                      AppButton(
                        label: l10n.dashboardHowItWorks,
                        variant: AppButtonVariant.text,
                        onPressed: () => showWhyCookieSheet(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyIllustration extends StatelessWidget {
  const _EmptyIllustration();

  static const double _size = 148;
  static const double _inner = 80;
  static const double _badge = 36;
  static const double _badgeBorder = 3;
  static const double _badgeRight = 16;
  static const double _badgeBottom = 18;
  static const double _userIcon = 32;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: _size,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DashedRingPainter(color: colors.border2),
              ),
            ),
            Center(
              child: Container(
                width: _inner,
                height: _inner,
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border),
                  boxShadow: context.elevation.card,
                ),
                child: Icon(
                  LucideIcons.user,
                  size: _userIcon,
                  color: colors.text2,
                ),
              ),
            ),
            Positioned(
              right: _badgeRight,
              bottom: _badgeBottom,
              child: Container(
                width: _badge,
                height: _badge,
                decoration: BoxDecoration(
                  color: BrandColors.lime,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.bg, width: _badgeBorder),
                ),
                child: const AppIcon(
                  LucideIcons.plus,
                  size: AppIconSize.inline,
                  color: BrandColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter({required this.color});

  static const double _stroke = 10;
  static const double _radius = 62;
  static const double _dash = 4;
  static const double _gap = 14;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: _radius,
    );
    const circumference = 2 * math.pi * _radius;
    final count = (circumference / (_dash + _gap)).floor();
    final step = 2 * math.pi / count;
    const sweep = _dash / _radius;
    for (var i = 0; i < count; i++) {
      canvas.drawArc(rect, i * step, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter oldDelegate) =>
      oldDelegate.color != color;
}
