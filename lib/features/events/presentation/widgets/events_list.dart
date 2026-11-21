import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_card.dart';
import 'package:hoyo_aio/core/design_system/components/app_segmented_control.dart';
import 'package:hoyo_aio/core/design_system/components/app_toggle.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/game_labels.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/events/data/events_repository_impl.dart';
import 'package:hoyo_aio/features/events/domain/web_event.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class EventsList extends StatefulWidget {
  const EventsList({required this.events, required this.now, super.key});

  final List<WebEvent> events;
  final DateTime now;

  @override
  State<EventsList> createState() => _EventsListState();
}

class _EventsListState extends State<EventsList> {
  var _phase = EventPhase.running;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shown = [
      for (final event in widget.events)
        if (event.phaseAt(widget.now) == _phase) event,
    ];
    if (_phase == EventPhase.ended) {
      shown.sort((a, b) => b.endAt.compareTo(a.endAt));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.cardGap,
      children: [
        const SizedBox(height: AppSpacing.s4),
        AppSegmentedControl<EventPhase>(
          options: [
            SegmentOption(value: EventPhase.running, label: l10n.eventsRunning),
            SegmentOption(
              value: EventPhase.upcoming,
              label: l10n.eventsUpcoming,
            ),
            SegmentOption(value: EventPhase.ended, label: l10n.eventsEnded),
          ],
          selected: _phase,
          onChanged: (phase) => setState(() => _phase = phase),
        ),
        if (shown.isEmpty)
          Text(
            l10n.eventsEmpty,
            style: AppTextStyles.bodyM.copyWith(color: context.colors.text2),
          ),
        for (final (index, event) in shown.indexed)
          index == 0 && _phase == EventPhase.running
              ? _FeaturedEvent(event: event, now: widget.now)
              : _CompactEvent(event: event, now: widget.now),
      ],
    );
  }
}

String _timing(AppLocalizations l10n, WebEvent event, DateTime now) =>
    switch (event.phaseAt(now)) {
      EventPhase.running => l10n.eventsEndsIn(
        l10n.duration(event.endAt.difference(now)),
      ),
      EventPhase.upcoming => l10n.eventsStartsIn(
        l10n.duration(event.startAt.difference(now)),
      ),
      EventPhase.ended => l10n.eventsEndedOn(l10n.atTime(event.endAt, now)),
    };

Future<void> _open(WebEvent event) =>
    launchUrl(eventUri(event), mode: LaunchMode.externalApplication);

class _Banner extends StatelessWidget {
  const _Banner({required this.event, required this.height});

  static const _rings = [96.0, 64.0, 32.0];
  static const double _ringBaseAlpha = 0.35;
  static const double _ringAlphaStep = 0.2;
  static const double _ringWidth = 2;

  final WebEvent event;
  final double height;

  @override
  Widget build(BuildContext context) {
    final accent = context.gameAccent(event.game);
    final colors = context.colors;
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.soft, colors.surface2],
        ),
      ),
      child: Stack(
        children: [
          for (final (index, size) in _rings.indexed)
            Positioned(
              right: AppSpacing.s24 - index * AppSpacing.s4,
              top: height / 2 - size / 2,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.acc.withValues(
                      alpha: _ringBaseAlpha + index * _ringAlphaStep,
                    ),
                    width: _ringWidth,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeaturedEvent extends ConsumerWidget {
  const _FeaturedEvent({required this.event, required this.now});

  static const double _bannerHeight = 112;

  final WebEvent event;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              _Banner(event: event, height: _bannerHeight),
              Positioned(
                left: AppSpacing.s12,
                top: AppSpacing.s12,
                child: AppBadge(label: l10n.gameShortName(event.game)),
              ),
              if (event.unread)
                Positioned(
                  left: AppSpacing.s12,
                  bottom: AppSpacing.s12,
                  child: AppBadge(
                    label: l10n.codesNew,
                    variant: AppBadgeVariant.success,
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.s8,
              children: [
                Text(
                  event.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleM.copyWith(color: colors.text),
                ),
                if (event.summary.isNotEmpty)
                  Text(
                    event.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyM.copyWith(color: colors.text2),
                  ),
                AppBadge(
                  label: _timing(l10n, event, now),
                  variant: AppBadgeVariant.warning,
                  icon: LucideIcons.clock,
                ),
                Divider(color: colors.border),
                Row(
                  spacing: AppSpacing.s8,
                  children: [
                    AppToggle(
                      value: event.remind,
                      semanticLabel: l10n.eventsRemind,
                      onChanged: (remind) => unawaited(
                        ref
                            .read(eventsRepositoryProvider)
                            .setRemind(event.id, remind: remind),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l10n.eventsRemind,
                        style: AppTextStyles.caption.copyWith(
                          color: colors.text2,
                        ),
                      ),
                    ),
                    AppButton(
                      label: l10n.eventsOpen,
                      size: AppButtonSize.small,
                      expand: false,
                      onPressed: () => unawaited(_open(event)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactEvent extends ConsumerWidget {
  const _CompactEvent({required this.event, required this.now});

  static const double _thumb = 64;

  final WebEvent event;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final accent = context.gameAccent(event.game);
    final phase = event.phaseAt(now);
    return GestureDetector(
      onTap: () => unawaited(_open(event)),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Row(
          spacing: AppSpacing.s12,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.input),
              child: SizedBox(
                width: _thumb,
                height: _thumb,
                child: Stack(
                  children: [
                    _Banner(event: event, height: _thumb),
                    Center(
                      child: AppIcon(
                        LucideIcons.calendarDays,
                        color: accent.accInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.s4,
                children: [
                  Text(
                    event.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.rowTitle.copyWith(color: colors.text),
                  ),
                  Text(
                    '${l10n.gameShortName(event.game)} · '
                    '${_timing(l10n, event, now)}',
                    style: AppTextStyles.caption.copyWith(color: colors.text2),
                  ),
                ],
              ),
            ),
            if (phase != EventPhase.ended)
              AppToggle(
                value: event.remind,
                semanticLabel: l10n.eventsRemind,
                onChanged: (remind) => unawaited(
                  ref
                      .read(eventsRepositoryProvider)
                      .setRemind(event.id, remind: remind),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
