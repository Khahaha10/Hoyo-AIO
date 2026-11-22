import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_segmented_control.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/game_labels.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/selected_role_provider.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/dashboard/presentation/states/dashboard_error.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/domain/endgame_models.dart';
import 'package:hoyo_aio/features/databook/presentation/databook_format.dart';
import 'package:hoyo_aio/features/databook/presentation/providers/databook_provider.dart';
import 'package:hoyo_aio/features/databook/presentation/providers/endgame_detail_provider.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/databook_skeleton.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/endgame_empty.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/endgame_highlights_card.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/endgame_section_card.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/endgame_stats_card.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class EndgameScreen extends ConsumerStatefulWidget {
  const EndgameScreen({required this.mode, super.key});

  final EndgameMode mode;

  @override
  ConsumerState<EndgameScreen> createState() => _EndgameScreenState();
}

class _EndgameScreenState extends ConsumerState<EndgameScreen> {
  var _previous = false;

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(selectedRoleProvider);
    if (role == null || role.game != widget.mode.game) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final l10n = context.l10n;
    final colors = context.colors;
    final accent = context.gameAccent(role.game);
    final now = ref.watch(clockProvider)();
    final characters =
        ref.watch(databookProvider(role)).value?.characters?.data ??
        const <ChronicleCharacter>[];
    final roster = {for (final c in characters) c.id: c};
    final detail = ref.watch(
      endgameDetailProvider(role, widget.mode, _previous),
    );
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.s8,
                AppSpacing.gutter,
                0,
              ),
              child: Row(
                spacing: AppSpacing.s12,
                children: [
                  if (context.canPop())
                    AppIconButton(
                      icon: LucideIcons.chevronLeft,
                      semanticLabel: l10n.commonBack,
                      onPressed: context.pop,
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            l10n.modeName(widget.mode),
                            style: AppTextStyles.screenTitle.copyWith(
                              color: colors.text,
                            ),
                          ),
                        ),
                        Row(
                          spacing: AppSpacing.s4,
                          children: [
                            Icon(Icons.circle, size: 8, color: accent.acc),
                            Text(
                              l10n.gameName(role.game),
                              style: AppTextStyles.caption.copyWith(
                                color: colors.text2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.s12,
                AppSpacing.gutter,
                AppSpacing.s8,
              ),
              child: AppSegmentedControl<bool>(
                expand: true,
                selected: _previous,
                onChanged: (value) => setState(() => _previous = value),
                options: [
                  SegmentOption(value: false, label: l10n.databookCurrent),
                  SegmentOption(value: true, label: l10n.databookPrevious),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  0,
                  AppSpacing.gutter,
                  AppSpacing.s24,
                ),
                children: [
                  switch (detail) {
                    AsyncData(:final value) => _Body(
                      detail: value.data,
                      role: role,
                      now: now,
                      previous: _previous,
                      roster: roster,
                      onViewPrevious: () => setState(() => _previous = true),
                    ),
                    AsyncError(:final error) => DashboardError(
                      error: error,
                      onRetry: () => ref.invalidate(endgameDetailProvider),
                    ),
                    _ => const DatabookSkeleton(),
                  },
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.detail,
    required this.role,
    required this.now,
    required this.previous,
    required this.roster,
    required this.onViewPrevious,
  });

  final EndgameDetail detail;
  final SavedRole role;
  final DateTime now;
  final bool previous;
  final Map<int, ChronicleCharacter> roster;
  final VoidCallback onViewPrevious;

  @override
  Widget build(BuildContext context) {
    final summary = detail.summary;
    final sections = detail.sections;
    if (!summary.attempted) {
      return EndgameEmpty(
        summary: summary,
        now: now,
        previous: previous,
        onViewPrevious: onViewPrevious,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.s12,
      children: [
        _PeriodRow(summary: summary, now: now, previous: previous),
        EndgameStatsCard(detail: detail),
        EndgameHighlightsCard(highlights: detail.highlights, roster: roster),
        if (sections.isNotEmpty)
          EndgameSectionCard(section: sections.first, roster: roster),
        if (sections.length > 1)
          EndgameSectionFolds(
            sections: sections.skip(1).toList(),
            roster: roster,
          ),
      ],
    );
  }
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({
    required this.summary,
    required this.now,
    required this.previous,
  });

  final EndgameSummary summary;
  final DateTime now;
  final bool previous;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final start = summary.startsAt;
    final end = summary.endsAt;
    final format = DateFormat.MMMd(l10n.localeName);
    final left = previous ? null : summary.timeLeft(now);
    final style = AppTextStyles.caption.copyWith(color: colors.text2);
    return Row(
      spacing: AppSpacing.s4,
      children: [
        AppIcon(
          LucideIcons.calendar,
          size: AppIconSize.badge,
          color: colors.text3,
        ),
        if (start != null && end != null)
          Expanded(
            child: Text(
              l10n.databookPeriod(
                format.format(start.toLocal()),
                format.format(end.toLocal()),
              ),
              style: style,
            ),
          )
        else
          const Spacer(),
        if (left != null) ...[
          AppIcon(
            LucideIcons.clock,
            size: AppIconSize.badge,
            color: colors.warning,
          ),
          Text(
            l10n.databookResetsIn(l10n.duration(left)),
            style: style.copyWith(
              color: colors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
