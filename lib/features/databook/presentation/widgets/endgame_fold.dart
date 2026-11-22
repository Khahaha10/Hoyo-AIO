import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/endgame_row_tile.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class EndgameFold extends StatefulWidget {
  const EndgameFold({
    required this.title,
    required this.rows,
    required this.roster,
    this.summary,
    super.key,
  });

  static const double _minHeight = 48;

  final String title;
  final String? summary;
  final List<EndgameRow> rows;
  final Map<int, ChronicleCharacter> roster;

  @override
  State<EndgameFold> createState() => _EndgameFoldState();
}

class _EndgameFoldState extends State<EndgameFold> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final summary = widget.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: EndgameFold._minHeight,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTextStyles.rowTitle.copyWith(color: colors.text),
                  ),
                ),
                if (summary != null)
                  Text(
                    summary,
                    style: AppTextStyles.tabular(AppTextStyles.label)
                        .copyWith(color: colors.text2),
                  ),
                AppIcon(
                  _open ? LucideIcons.chevronUp : LucideIcons.chevronRight,
                  color: colors.text3,
                ),
              ],
            ),
          ),
        ),
        if (_open)
          for (final row in widget.rows) ...[
            Divider(height: 1, color: colors.border),
            EndgameRowTile(row: row, roster: widget.roster),
          ],
      ],
    );
  }
}
