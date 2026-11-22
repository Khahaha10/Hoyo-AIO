import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';
import 'package:hoyo_aio/features/databook/presentation/endgame_format.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/chronicle_avatar.dart';
import 'package:material_ui/material_ui.dart';

class EndgameTeams extends StatelessWidget {
  const EndgameTeams({required this.teams, required this.roster, super.key});

  static const double _panelAvatar = 32;

  final List<EndgameTeam> teams;
  final Map<int, ChronicleCharacter> roster;

  Widget _avatars(EndgameTeam team, double size) => Wrap(
    spacing: AppSpacing.s4,
    runSpacing: AppSpacing.s4,
    children: [
      for (final member in team.members)
        ChronicleAvatar(
          name: member.name ?? roster[member.id]?.name ?? '',
          element: member.element ?? roster[member.id]?.element,
          imageUrl: memberIcon(member.iconUrl, roster[member.id]),
          rarity: member.rarity ?? roster[member.id]?.rarity,
          size: size,
        ),
    ],
  );

  String _details(AppLocalizations l10n, EndgameTeam team) => [
    if (team.rounds case final rounds?) l10n.databookRounds(rounds),
    if (team.score case final score?)
      l10n.databookScoreValue(l10n.number(score)),
  ].join(' · ');

  Widget _panel(BuildContext context, EndgameTeam team) {
    final colors = context.colors;
    final l10n = context.l10n;
    final details = _details(l10n, team);
    final note = team.note;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.iconTile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.s8,
        children: [
          Row(
            spacing: AppSpacing.s8,
            children: [
              Text(
                l10n.teamLabel(team.label),
                style: AppTextStyles.label.copyWith(color: colors.text),
              ),
              Expanded(
                child: Text(
                  details,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.tabular(AppTextStyles.label)
                      .copyWith(color: colors.text2),
                ),
              ),
            ],
          ),
          if (note != null)
            Text(
              note,
              style: AppTextStyles.caption.copyWith(color: colors.text2),
            ),
          _avatars(team, _panelAvatar),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpacing.s8,
    children: [for (final team in teams) _panel(context, team)],
  );
}
