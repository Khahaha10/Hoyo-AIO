import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';
import 'package:hoyo_aio/features/databook/presentation/endgame_format.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/chronicle_avatar.dart';
import 'package:material_ui/material_ui.dart';

class EndgameHighlightsCard extends StatelessWidget {
  const EndgameHighlightsCard({
    required this.highlights,
    required this.names,
    super.key,
  });

  static const double _avatar = 32;

  final List<EndgameHighlight> highlights;
  final Map<int, String> names;

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.s12,
        children: [
          Text(
            l10n.databookHighlights,
            style: AppTextStyles.titleM.copyWith(color: colors.text),
          ),
          for (final item in highlights)
            Row(
              spacing: AppSpacing.s12,
              children: [
                ChronicleAvatar(
                  name: names[item.avatarId] ?? '',
                  element: null,
                  imageUrl: item.iconUrl,
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
                      if (names[item.avatarId] case final name?)
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
        ],
      ),
    );
  }
}
