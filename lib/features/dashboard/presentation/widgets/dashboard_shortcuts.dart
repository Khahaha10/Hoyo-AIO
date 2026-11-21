import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/codes/data/codes_repository_impl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class DashboardShortcuts extends ConsumerWidget {
  const DashboardShortcuts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final unread = ref.watch(unreadCodesProvider);
    return Row(
      spacing: AppSpacing.s8,
      children: [
        Expanded(
          child: _Shortcut(
            icon: LucideIcons.ticket,
            title: l10n.codesShortcut,
            subtitle: unread > 0
                ? l10n.codesNewCount(unread)
                : l10n.codesNoneNew,
            onTap: () => context.push(AppRoutes.codes),
          ),
        ),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  static const double _tile = 32;
  static const double _tileRadius = 10;
  static const double _cardRadius = 18;
  static const double _padding = 10;

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AppCard(
          radius: _cardRadius,
          padding: const EdgeInsets.all(_padding),
          child: Row(
            spacing: AppSpacing.s8,
            children: [
              Container(
                width: _tile,
                height: _tile,
                decoration: BoxDecoration(
                  color: BrandColors.lime,
                  borderRadius: BorderRadius.circular(_tileRadius),
                ),
                child: Center(
                  child: AppIcon(
                    icon,
                    size: AppIconSize.inline,
                    color: BrandColors.ink,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.label.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.text2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
