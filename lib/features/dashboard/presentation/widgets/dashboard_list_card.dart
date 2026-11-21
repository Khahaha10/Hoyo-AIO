import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

class DashboardListCard extends StatelessWidget {
  const DashboardListCard({
    required this.title,
    required this.rows,
    this.trailing,
    super.key,
  });

  static const double _headerTop = 14;
  static const double _headerBottom = 6;

  final String title;
  final String? trailing;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              _headerTop,
              AppSpacing.s16,
              _headerBottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: AppTextStyles.bodyL.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: AppTextStyles.tabular(AppTextStyles.label).copyWith(
                      color: colors.text2,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
          for (final row in rows)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: row,
            ),
        ],
      ),
    );
  }
}
