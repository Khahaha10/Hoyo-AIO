import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';
import 'package:hoyo_aio/features/databook/presentation/endgame_format.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/chronicle_avatar.dart';
import 'package:material_ui/material_ui.dart';

class EndgameTeamRow extends StatelessWidget {
  const EndgameTeamRow({required this.team, required this.names, super.key});

  static const double _avatar = 24;
  static const double _labelWidth = 48;

  final EndgameTeam team;
  final Map<int, String> names;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.caption.copyWith(color: context.colors.text3);
    return Row(
      spacing: AppSpacing.s4,
      children: [
        SizedBox(
          width: _labelWidth,
          child: Text(
            context.l10n.teamLabel(team.label),
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: AppSpacing.s4,
            runSpacing: AppSpacing.s4,
            children: [
              for (final member in team.members)
                ChronicleAvatar(
                  name: member.name ?? names[member.id] ?? '',
                  element: member.element,
                  imageUrl: member.iconUrl,
                  rarity: member.rarity,
                  size: _avatar,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
