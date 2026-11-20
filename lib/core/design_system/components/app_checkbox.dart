import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    super.key,
  });

  static const boxKey = ValueKey('app-checkbox-box');
  static const double _box = 24;
  static const double _hit = 44;

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onChanged != null;
    return Semantics(
      checked: value,
      enabled: enabled,
      label: semanticLabel,
      onTap: enabled ? () => onChanged!(!value) : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: SizedBox.square(
          dimension: _hit,
          child: Center(
            child: Container(
              key: boxKey,
              width: _box,
              height: _box,
              decoration: BoxDecoration(
                color: value ? BrandColors.lime : null,
                borderRadius: BorderRadius.circular(AppRadius.code),
                border: Border.all(
                  color: value ? BrandColors.lime : colors.border2,
                  width: 2,
                ),
              ),
              child: value
                  ? const AppIcon(
                      LucideIcons.check,
                      size: AppIconSize.inline,
                      color: BrandColors.ink,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
