import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';
import 'package:hoyo_aio/features/databook/presentation/endgame_format.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/endgame_row_tile.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class EndgameSectionCard extends StatefulWidget {
  const EndgameSectionCard({
    required this.section,
    required this.names,
    this.initiallyOpen = true,
    this.visibleRows = 4,
    super.key,
  });

  final EndgameSection section;
  final Map<int, String> names;
  final bool initiallyOpen;
  final int visibleRows;

  @override
  State<EndgameSectionCard> createState() => _EndgameSectionCardState();
}

class _EndgameSectionCardState extends State<EndgameSectionCard> {
  late var _open = widget.initiallyOpen;
  var _all = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final section = widget.section;
    final rows = section.rows;
    final hidden = rows.length - widget.visibleRows;
    final shown = _all || hidden <= 0
        ? rows
        : rows.take(widget.visibleRows).toList();
    final stars = section.stars;
    final maxStars = section.maxStars;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.sectionTitle(section),
                      style: AppTextStyles.titleM.copyWith(color: colors.text),
                    ),
                  ),
                  if (stars != null && maxStars != null)
                    Text(
                      l10n.databookStarsValue(stars, maxStars),
                      style: AppTextStyles.tabular(AppTextStyles.label)
                          .copyWith(color: colors.text2),
                    ),
                  const SizedBox(width: AppSpacing.s8),
                  AppIcon(
                    _open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    color: colors.text3,
                  ),
                ],
              ),
            ),
          ),
          if (_open) ...[
            for (final row in shown) ...[
              Divider(height: 1, color: colors.border),
              EndgameRowTile(row: row, names: widget.names),
            ],
            if (hidden > 0)
              InkWell(
                onTap: () => setState(() => _all = !_all),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _all
                          ? l10n.databookShowLess
                          : l10n.databookShowMore(hidden),
                      style: AppTextStyles.label.copyWith(color: colors.text2),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
