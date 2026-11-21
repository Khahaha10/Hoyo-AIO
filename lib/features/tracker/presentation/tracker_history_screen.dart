import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_snackbar.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/error/app_exception_l10n.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_record.dart';
import 'package:hoyo_aio/features/tracker/presentation/providers/tracker_providers.dart';
import 'package:hoyo_aio/features/tracker/presentation/tracker_labels.dart';
import 'package:hoyo_aio/features/tracker/presentation/widgets/import_sheet.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

class TrackerHistoryScreen extends ConsumerStatefulWidget {
  const TrackerHistoryScreen({
    required this.game,
    required this.banner,
    super.key,
  });

  final Game game;
  final String banner;

  @override
  ConsumerState<TrackerHistoryScreen> createState() =>
      _TrackerHistoryScreenState();
}

class _TrackerHistoryScreenState extends ConsumerState<TrackerHistoryScreen> {
  static const _ranks = [5, 4, 3];

  var _shown = {5, 4};

  Future<void> _update() async {
    final l10n = context.l10n;
    try {
      await ref.read(gachaSyncProvider.notifier).sync(widget.game);
    } on AuthkeyExpiredException {
      if (mounted) await showImportSheet(context);
    } on AppException catch (error) {
      if (!mounted) return;
      showAppSnackbar(
        context,
        message: error.localizedMessage(l10n),
        icon: LucideIcons.wifiOff,
      );
    }
  }

  Future<void> _export(List<GachaRecord> records) async {
    final rows = [
      'time,name,item_type,rank,banner,id',
      for (final record in records)
        [
          record.time,
          _csv(record.name),
          _csv(record.itemType),
          record.rank,
          record.banner,
          record.id,
        ].join(','),
    ];
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            utf8.encode('${rows.join('\n')}\n'),
            mimeType: 'text/csv',
          ),
        ],
        fileNameOverrides: ['${widget.game.name}_${widget.banner}.csv'],
      ),
    );
  }

  static String _csv(String value) => value.contains(RegExp('[",\n]'))
      ? '"${value.replaceAll('"', '""')}"'
      : value;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final game = widget.game;
    final all = [
      for (final record
          in ref.watch(gachaRecordsProvider(game)).value ??
              const <GachaRecord>[])
        if (record.banner == widget.banner) record,
    ];
    final pity = ref.watch(bannerPityProvider(game, widget.banner));
    final records = [
      for (final record in all)
        if (_shown.contains(record.rank)) record,
    ];
    final groups = <String, List<GachaRecord>>{};
    for (final record in records) {
      (groups[record.time] ??= []).add(record);
    }
    final batchSizes = <String, int>{};
    for (final record in all) {
      batchSizes[record.time] = (batchSizes[record.time] ?? 0) + 1;
    }
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.trackerHistoryTitle(game),
                        style: AppTextStyles.screenTitle.copyWith(
                          color: colors.text,
                        ),
                      ),
                      Text(
                        '${l10n.trackerBanner(game, widget.banner)} · '
                        '${l10n.trackerPulls(game, all.length)}',
                        style: AppTextStyles.caption.copyWith(
                          color: colors.text2,
                        ),
                      ),
                    ],
                  ),
                ),
                AppIconButton(
                  icon: LucideIcons.download,
                  semanticLabel: l10n.trackerExport,
                  onPressed: all.isEmpty ? null : () => unawaited(_export(all)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            _SyncCard(game: game, onUpdate: () => unawaited(_update())),
            const SizedBox(height: AppSpacing.s12),
            Row(
              spacing: AppSpacing.s8,
              children: [
                for (final rank in _ranks)
                  _RankChip(
                    rank: rank,
                    selected: _shown.contains(rank),
                    onTap: () => setState(() {
                      _shown = _shown.contains(rank)
                          ? ({..._shown}..remove(rank))
                          : {..._shown, rank};
                    }),
                  ),
                const Spacer(),
                Text(
                  l10n.trackerNewestFirst,
                  style: AppTextStyles.caption.copyWith(color: colors.text2),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            if (records.isEmpty)
              Text(
                l10n.trackerNoRecords,
                style: AppTextStyles.bodyM.copyWith(color: colors.text2),
              )
            else
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final MapEntry(key: time, value: batch)
                        in groups.entries) ...[
                      _GroupHeader(
                        time: time,
                        size: batchSizes[time] ?? batch.length,
                        game: game,
                      ),
                      for (final record in batch)
                        _RecordRow(record: record, pity: pity),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SyncCard extends ConsumerWidget {
  const _SyncCard({required this.game, required this.onUpdate});

  static const double _tile = 44;

  final Game game;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final sync = ref.watch(gachaSyncProvider);
    final expires = ref.watch(gachaLinkExpiryProvider(game)).value;
    ref.watch(clockTickProvider);
    final now = ref.watch(clockProvider)();
    final synced = sync.lastSynced[game];
    final valid = expires != null && expires.isAfter(now);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Row(
        spacing: AppSpacing.s12,
        children: [
          Container(
            width: _tile,
            height: _tile,
            decoration: BoxDecoration(
              color: valid ? colors.successBg : colors.warningBg,
              borderRadius: BorderRadius.circular(AppRadius.iconTile),
            ),
            child: Center(
              child: AppIcon(
                valid ? LucideIcons.link : LucideIcons.unlink,
                color: valid ? colors.success : colors.warning,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sync.syncing == game
                      ? l10n.trackerFetched(sync.fetched)
                      : synced != null
                      ? l10n.trackerSynced(l10n.lastUpdated(synced, now))
                      : valid
                      ? l10n.trackerLinkValid(
                          l10n.duration(expires.difference(now)),
                        )
                      : l10n.trackerLinkExpired,
                  style: AppTextStyles.rowTitle.copyWith(color: colors.text),
                ),
                Text(
                  l10n.trackerUpdateHint(l10n.trackerHistoryTitle(game)),
                  style: AppTextStyles.rowSubtitle.copyWith(
                    color: colors.text2,
                  ),
                ),
              ],
            ),
          ),
          AppButton(
            label: l10n.trackerUpdate,
            size: AppButtonSize.small,
            expand: false,
            isLoading: sync.syncing == game,
            onPressed: onUpdate,
          ),
        ],
      ),
    );
  }
}

class _RankChip extends StatelessWidget {
  const _RankChip({
    required this.rank,
    required this.selected,
    required this.onTap,
  });

  static const double _height = 36;

  final int rank;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _height,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.text : colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? colors.text : colors.border),
        ),
        child: Text(
          '$rank★',
          style: AppTextStyles.chip.copyWith(
            color: selected ? colors.bg : colors.text2,
          ),
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.time,
    required this.size,
    required this.game,
  });

  final String time;
  final int size;
  final Game game;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final at = DateTime.tryParse(time);
    final date = at == null
        ? time
        : DateFormat.MMMd(l10n.localeName).format(at);
    return Container(
      color: colors.surface2,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s8,
      ),
      child: Text(
        l10n.trackerBatch(date, size).toUpperCase(),
        style: AppTextStyles.overline.copyWith(color: colors.text2),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record, required this.pity});

  static const double _height = 56;
  static const double _pillWidth = 44;
  static const _clockStart = 11;
  static const _clockEnd = 16;

  final GachaRecord record;
  final BannerPity pity;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final five = record.rank >= BannerPity.fiveStar;
    final four = record.rank == BannerPity.fourStar;
    final rowPity = pity.rowPity[record.id];
    final result = pity.fiveStarFor(record.id)?.fiftyFifty;
    final clock = record.time.length >= _clockEnd
        ? record.time.substring(_clockStart, _clockEnd)
        : record.time;
    final (pillBg, pillFg) = five
        ? (colors.warningBg, colors.warning)
        : four
        ? (
            context.gameAccent(Game.starRail).soft,
            context.gameAccent(Game.starRail).accInk,
          )
        : (colors.surface2, colors.text2);
    return Container(
      constraints: const BoxConstraints(minHeight: _height),
      color: five ? colors.warningBg : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s8,
      ),
      child: Row(
        spacing: AppSpacing.s12,
        children: [
          Container(
            width: _pillWidth,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: five ? null : pillBg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '${record.rank}★',
              style: AppTextStyles.label.copyWith(color: pillFg),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.rowTitle.copyWith(color: colors.text),
                ),
                Text(
                  '${record.itemType} · $clock',
                  style: AppTextStyles.rowSubtitle.copyWith(
                    color: colors.text2,
                  ),
                ),
              ],
            ),
          ),
          if (rowPity != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$rowPity',
                  style: AppTextStyles.tabular(AppTextStyles.titleM)
                      .copyWith(color: colors.text),
                ),
                Text(switch (result) {
                  FiftyFifty.won => l10n.trackerWon.toLowerCase(),
                  FiftyFifty.lost => l10n.trackerLost.toLowerCase(),
                  _ => l10n.trackerPity,
                }, style: AppTextStyles.caption.copyWith(color: colors.text2)),
              ],
            ),
        ],
      ),
    );
  }
}
