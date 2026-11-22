import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/selected_role_provider.dart';
import 'package:hoyo_aio/features/dashboard/presentation/states/dashboard_error.dart';
import 'package:hoyo_aio/features/databook/domain/chronicle_models.dart';
import 'package:hoyo_aio/features/databook/presentation/chronicle_colors.dart';
import 'package:hoyo_aio/features/databook/presentation/providers/databook_provider.dart';
import 'package:hoyo_aio/features/databook/presentation/roster_logic.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/character_card.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/character_sheet.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/databook_skeleton.dart';
import 'package:hoyo_aio/features/databook/presentation/widgets/roster_chip.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class CharactersScreen extends ConsumerStatefulWidget {
  const CharactersScreen({super.key});

  @override
  ConsumerState<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends ConsumerState<CharactersScreen> {
  static const double _gridExtent = 124;
  static const double _maxTextScale = 1.6;

  var _filter = const RosterFilter();
  var _searching = false;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggleSearch() => setState(() {
    _searching = !_searching;
    if (!_searching) {
      _search.clear();
      _filter = _filter.withQuery('');
    }
  });

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(selectedRoleProvider);
    if (role == null) return const Scaffold(body: SizedBox.shrink());
    final databook = ref.watch(databookProvider(role));
    final all = databook.value?.characters?.data;
    final l10n = context.l10n;
    final isZzz = role.game == Game.zzz;
    final fiveStars = all?.where((c) => c.rarity >= 5).length ?? 0;
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
                            isZzz
                                ? l10n.databookAgentsTitle
                                : l10n.databookCharactersTitle,
                            style: AppTextStyles.screenTitle.copyWith(
                              color: context.colors.text,
                            ),
                          ),
                        ),
                        if (all != null)
                          Text(
                            isZzz
                                ? l10n.databookRosterAgents(
                                    all.length,
                                    fiveStars,
                                  )
                                : l10n.databookRosterCharacters(
                                    all.length,
                                    fiveStars,
                                  ),
                            style: AppTextStyles.caption.copyWith(
                              color: context.colors.text2,
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppIconButton(
                    icon: _searching ? LucideIcons.x : LucideIcons.search,
                    semanticLabel: l10n.databookSearch,
                    onPressed: _toggleSearch,
                  ),
                ],
              ),
            ),
            if (_searching)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.s8,
                  AppSpacing.gutter,
                  0,
                ),
                child: TextField(
                  controller: _search,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.databookSearchHint,
                  ),
                  onChanged: (value) =>
                      setState(() => _filter = _filter.withQuery(value)),
                ),
              ),
            Expanded(
              child: switch (databook) {
                _ when all != null => _Roster(
                  role: role,
                  all: all,
                  filter: _filter,
                  onFilter: (value) => setState(() => _filter = value),
                  gridExtent:
                      _gridExtent *
                      MediaQuery.textScalerOf(context)
                          .scale(1)
                          .clamp(1, _maxTextScale),
                ),
                AsyncError(:final error) => DashboardError(
                  error: error,
                  onRetry: ref.read(databookProvider(role).notifier).refresh,
                ),
                _ => const Padding(
                  padding: EdgeInsets.all(AppSpacing.gutter),
                  child: DatabookSkeleton(),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Roster extends StatelessWidget {
  const _Roster({
    required this.role,
    required this.all,
    required this.filter,
    required this.onFilter,
    required this.gridExtent,
  });

  final SavedRole role;
  final List<ChronicleCharacter> all;
  final RosterFilter filter;
  final ValueChanged<RosterFilter> onFilter;
  final double gridExtent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final game = role.game;
    final shown = RosterLogic.apply(game, all, filter);
    return Column(
      children: [
        _FilterBar(game: game, all: all, filter: filter, onFilter: onFilter),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Text(
                    l10n.databookNoMatches,
                    style: AppTextStyles.bodyM.copyWith(
                      color: context.colors.text2,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.s8,
                    AppSpacing.gutter,
                    AppSpacing.s24,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: AppSpacing.s8,
                    crossAxisSpacing: AppSpacing.s8,
                    mainAxisExtent: gridExtent,
                  ),
                  itemCount: shown.length,
                  itemBuilder: (context, index) => CharacterCard(
                    game: game,
                    character: shown[index],
                    onTap: () => showCharacterSheet(
                      context,
                      role: role,
                      character: shown[index],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.game,
    required this.all,
    required this.filter,
    required this.onFilter,
  });

  final Game game;
  final List<ChronicleCharacter> all;
  final RosterFilter filter;
  final ValueChanged<RosterFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final isZzz = game == Game.zzz;
    final chips = RosterLogic.chipValues(game, all);
    final menu = RosterLogic.menuValues(game, all);
    const pad = EdgeInsets.symmetric(horizontal: AppSpacing.gutter);
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: pad,
          child: Row(
            spacing: AppSpacing.s8,
            children: [
              for (final rarity in const [5, 4])
                RosterChip(
                  label: isZzz
                      ? l10n.databookRankChip(rarity == 5 ? 'S' : 'A')
                      : l10n.databookRarityChip(rarity),
                  selected: filter.rarities.contains(rarity),
                  onTap: () => onFilter(filter.toggleRarity(rarity)),
                ),
              Container(width: 1, height: 20, color: colors.border2),
              for (final value in chips)
                RosterChip(
                  label: game == Game.starRail
                      ? l10n.databookKindName(value)
                      : l10n.databookElementName(value),
                  dotColor: game == Game.starRail
                      ? null
                      : chronicleElementColor(value),
                  selected: filter.chip == value,
                  onTap: () => onFilter(filter.withChip(value)),
                ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: pad,
          child: Row(
            spacing: AppSpacing.s8,
            children: [
              PopupMenuButton<String>(
                tooltip: l10n.databookFilterName(game.name),
                onSelected: (value) =>
                    onFilter(filter.withMenu(value.isEmpty ? null : value)),
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    value: '',
                    child: Text(l10n.databookFilterAll),
                  ),
                  for (final value in menu)
                    PopupMenuItem<String>(
                      value: value,
                      child: Text(
                        game == Game.starRail
                            ? l10n.databookElementName(value)
                            : l10n.databookKindName(value),
                      ),
                    ),
                ],
                child: IgnorePointer(
                  child: RosterChip(
                    label: l10n.databookFilterWith(
                      l10n.databookFilterName(game.name),
                      filter.menu == null
                          ? l10n.databookFilterAll
                          : (game == Game.starRail
                                ? l10n.databookElementName(filter.menu!)
                                : l10n.databookKindName(filter.menu!)),
                    ),
                    selected: filter.menu != null,
                    trailingIcon: rosterMenuIcon,
                  ),
                ),
              ),
              PopupMenuButton<RosterSort>(
                onSelected: (value) => onFilter(filter.withSort(value)),
                itemBuilder: (_) => [
                  for (final sort in RosterLogic.sortsFor(game))
                    PopupMenuItem<RosterSort>(
                      value: sort,
                      child: Text(
                        l10n.databookSortLabel(RosterLogic.sortId(game, sort)),
                      ),
                    ),
                ],
                child: IgnorePointer(
                  child: RosterChip(
                    label: l10n.databookSortLabel(
                      RosterLogic.sortId(game, filter.sort),
                    ),
                    selected: false,
                    trailingIcon: rosterSortIcon,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
