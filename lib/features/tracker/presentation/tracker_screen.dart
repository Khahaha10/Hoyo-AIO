import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_segmented_control.dart';
import 'package:hoyo_aio/core/design_system/components/app_snackbar.dart';
import 'package:hoyo_aio/core/design_system/components/game_switcher_chip.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/error/app_exception_l10n.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/tracker/presentation/providers/tracker_providers.dart';
import 'package:hoyo_aio/features/tracker/presentation/tracker_labels.dart';
import 'package:hoyo_aio/features/tracker/presentation/widgets/import_sheet.dart';
import 'package:hoyo_aio/features/tracker/presentation/widgets/tracker_cards.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class TrackerScreen extends ConsumerStatefulWidget {
  const TrackerScreen({required this.game, super.key});

  final Game game;

  @override
  ConsumerState<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends ConsumerState<TrackerScreen> {
  static const _shownBanners = 3;
  static const _previewFiveStars = 3;

  late var _game = widget.game;
  String? _banner;

  List<String> get _banners =>
      (HoyolabConfig.gachaBanners[_game] ?? const <String>[])
          .take(_shownBanners)
          .toList();

  Future<void> _sync() async {
    final l10n = context.l10n;
    try {
      await ref.read(gachaSyncProvider.notifier).sync(_game);
    } on AuthkeyExpiredException {
      if (!mounted) return;
      await _import();
    } on AppException catch (error) {
      if (!mounted) return;
      showAppSnackbar(
        context,
        message: error.localizedMessage(l10n),
        icon: LucideIcons.wifiOff,
      );
    }
  }

  Future<void> _import() async {
    final game = await showImportSheet(context);
    if (game != null && mounted) setState(() => _game = game);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final banner = _banners.firstWhere(
      (key) => key == _banner,
      orElse: () => _banners.first,
    );
    final records = ref.watch(gachaRecordsProvider(_game)).value ?? const [];
    final pity = ref.watch(bannerPityProvider(_game, banner));
    final sync = ref.watch(gachaSyncProvider);
    final (hard, _) = pityLimits(_game, banner);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.s8,
            AppSpacing.gutter,
            AppSpacing.s24,
          ),
          children: [
            Row(
              spacing: AppSpacing.s12,
              children: [
                AppIconButton(
                  icon: LucideIcons.chevronLeft,
                  semanticLabel: l10n.commonBack,
                  onPressed: context.pop,
                ),
                Expanded(
                  child: Text(
                    l10n.trackerTitle(_game),
                    style: AppTextStyles.screenTitle.copyWith(
                      color: colors.text,
                    ),
                  ),
                ),
                AppIconButton(
                  icon: LucideIcons.refreshCw,
                  semanticLabel: l10n.dashboardRefresh,
                  onPressed: sync.syncing != null
                      ? null
                      : () => unawaited(_sync()),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 6,
                children: [
                  for (final game in trackerGames)
                    GameSwitcherChip(
                      game: game,
                      label: l10n.trackerChip(game),
                      selected: game == _game,
                      onTap: () => setState(() {
                        _game = game;
                        _banner = null;
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            AppSegmentedControl<String>(
              options: [
                for (final key in _banners)
                  SegmentOption(
                    value: key,
                    label: l10n.trackerBanner(_game, key),
                  ),
              ],
              selected: banner,
              onChanged: (value) => setState(() => _banner = value),
            ),
            const SizedBox(height: AppSpacing.s16),
            if (sync.syncing == _game) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: AppSpacing.s8),
              Text(
                l10n.trackerFetched(sync.fetched),
                style: AppTextStyles.caption.copyWith(color: colors.text2),
              ),
              const SizedBox(height: AppSpacing.s12),
            ],
            if (records.isEmpty)
              GachaEmptyCard(onImport: () => unawaited(_import()))
            else ...[
              PityHeroCard(game: _game, banner: banner, pity: pity),
              const SizedBox(height: AppSpacing.cardGap),
              Row(
                spacing: AppSpacing.s8,
                children: [
                  Expanded(
                    child: StatCard(
                      label: l10n.trackerTotal,
                      value: l10n.number(pity.total),
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      label: l10n.trackerAverage,
                      value: pity.averageFiveStar?.toStringAsFixed(1) ?? '–',
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      label: l10n.trackerFiftyFifty,
                      value: pity.fiftyFiftyTotal == 0
                          ? '–'
                          : l10n.trackerOf(
                              pity.fiftyFiftyWon,
                              pity.fiftyFiftyTotal,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.cardGap),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () =>
                          context.push(AppRoutes.trackerHistory(_game, banner)),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.trackerFiveStarHistory,
                                style: AppTextStyles.titleM.copyWith(
                                  color: colors.text,
                                ),
                              ),
                            ),
                            Text(
                              l10n.trackerAll(pity.fiveStars.length),
                              style: AppTextStyles.label.copyWith(
                                color: colors.text2,
                              ),
                            ),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 16,
                              color: colors.text2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (pity.fiveStars.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.s16,
                          0,
                          AppSpacing.s16,
                          AppSpacing.s16,
                        ),
                        child: Text(
                          l10n.trackerNoFiveStar,
                          style: AppTextStyles.bodyM.copyWith(
                            color: colors.text2,
                          ),
                        ),
                      ),
                    for (final (index, pull)
                        in pity.fiveStars.take(_previewFiveStars).indexed) ...[
                      if (index > 0) Divider(height: 1, color: colors.border),
                      FiveStarRow(pull: pull, game: _game, hard: hard),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
