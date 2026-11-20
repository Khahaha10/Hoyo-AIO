import 'dart:math' as math;

import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:material_ui/material_ui.dart';

class AppNavItem {
  const AppNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  static const double _topPadding = 9;
  static const double _minBottomPadding = 26;
  static const double _pillWidth = 56;
  static const double _pillHeight = 32;

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s8,
        _topPadding,
        AppSpacing.s8,
        math.max(bottomInset, _minBottomPadding),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(child: _item(context, items[i], i == currentIndex, i)),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, AppNavItem item, bool active, int index) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      onTap: () => onTap(index),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.s4,
          children: [
            Container(
              width: _pillWidth,
              height: _pillHeight,
              decoration: BoxDecoration(
                color: active ? BrandColors.lime : null,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: AppIcon(
                item.icon,
                color: active ? BrandColors.ink : colors.text3,
              ),
            ),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? colors.text : colors.text3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
