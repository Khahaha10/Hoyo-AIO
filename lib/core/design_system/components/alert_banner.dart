import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

class AlertBanner extends StatelessWidget {
  const AlertBanner({
    required this.icon,
    required this.title,
    required this.body,
    this.actions = const [],
    super.key,
  });

  static const double _iconTile = 36;
  static const double _actionsIndent = _iconTile + AppSpacing.s12;

  final IconData icon;
  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: colors.dangerBg,
          borderRadius: BorderRadius.circular(AppRadius.tile),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.s12,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.s12,
              children: [
                Container(
                  width: _iconTile,
                  height: _iconTile,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.iconTile),
                  ),
                  child: AppIcon(icon, color: colors.danger),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.s4,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyL.copyWith(
                          height: 22 / 16,
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                        ),
                      ),
                      Text(
                        body,
                        style: AppTextStyles.bodyM.copyWith(
                          fontSize: 14,
                          height: 20 / 14,
                          color: colors.text2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: _actionsIndent),
                child: Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: actions,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
