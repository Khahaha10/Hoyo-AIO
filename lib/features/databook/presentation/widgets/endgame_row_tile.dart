import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';
import 'package:hoyo_aio/features/databook/presentation/endgame_format.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/endgame_rating_pill.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/endgame_stars.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/endgame_team_row.dart';
import 'package:material_ui/material_ui.dart';

class EndgameRowTile extends StatelessWidget {
  const EndgameRowTile({required this.row, required this.roster, super.key});

  final EndgameRow row;
  final Map<int, ChronicleCharacter> roster;

  List<String> _details(AppLocalizations l10n) => [
    ?row.subtitle,
    if (row.time case final time?) l10n.clock(time),
    if (row.rounds case final rounds?) l10n.databookRounds(rounds),
    if (row.score case final score?)
      l10n.databookScoreValue(l10n.number(score)),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final details = _details(l10n);
    final stars = row.stars;
    final maxStars = row.maxStars;
    final rating = row.rating;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.s8,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.rowTitle(row),
                      style: AppTextStyles.rowTitle.copyWith(
                        color: colors.text,
                      ),
                    ),
                    if (details.isNotEmpty)
                      Text(
                        details.join(' · '),
                        style: AppTextStyles.caption.copyWith(
                          color: colors.text2,
                        ),
                      ),
                  ],
                ),
              ),
              if (rating != null)
                EndgameRatingPill(rating: rating)
              else if (stars != null && maxStars != null)
                EndgameStars(stars: stars, maxStars: maxStars),
            ],
          ),
          if (row.teams.isNotEmpty)
            EndgameTeams(teams: row.teams, roster: roster),
        ],
      ),
    );
  }
}
