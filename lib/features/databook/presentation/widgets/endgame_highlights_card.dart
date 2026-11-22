import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';
import 'package:hoyo_aio/features/databook/presentation/endgame_format.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/chronicle_avatar.dart';
import 'package:material_ui/material_ui.dart';

class EndgameHighlightsCard extends StatelessWidget {
  const EndgameHighlightsCard({
    required this.highlights,
    required this.roster,
    super.key,
  });

  static const double _avatar = 32;
  static const double _headerHeight = 52;

  final List<EndgameHighlight> highlights;
  final Map<int, ChronicleCharacter> roster;

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _headerHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.databookHighlights,
                style: AppTextStyles.titleM.copyWith(color: colors.text),
              ),
            ),
          ),
          for (final item in highlights) ...[
            Divider(height: 1, color: colors.border),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
              child: Row(
                spacing: AppSpacing.s12,
                children: [
                  ChronicleAvatar(
                    name: roster[item.avatarId]?.name ?? '',
                    element: roster[item.avatarId]?.element,
                    imageUrl: memberIcon(item.iconUrl, roster[item.avatarId]),
                    size: _avatar,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.highlightName(item.kind),
                          style: AppTextStyles.rowTitle.copyWith(
                            color: colors.text,
                          ),
                        ),
                        if (roster[item.avatarId]?.name case final name?)
                          Text(
                            name,
                            style: AppTextStyles.caption.copyWith(
                              color: colors.text2,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    l10n.number(item.value),
                    style: AppTextStyles.tabular(AppTextStyles.rowTitle)
                        .copyWith(color: colors.text),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
