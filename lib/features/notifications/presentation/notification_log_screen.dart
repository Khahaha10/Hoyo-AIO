import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/design_system/components/settings_row.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/notifications/data/notification_log_repository_impl.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_kind.dart';
import 'package:hoyo_aio/features/notifications/presentation/providers/notification_log_provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class NotificationLogScreen extends ConsumerStatefulWidget {
  const NotificationLogScreen({super.key});

  @override
  ConsumerState<NotificationLogScreen> createState() =>
      _NotificationLogScreenState();
}

class _NotificationLogScreenState extends ConsumerState<NotificationLogScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(
      ref
          .read(notificationLogRepositoryProvider)
          .markAllRead(ref.read(clockProvider)()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final entries = ref.watch(notificationLogProvider).value ?? const [];
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
                if (context.canPop())
                  AppIconButton(
                    icon: LucideIcons.chevronLeft,
                    semanticLabel: l10n.commonBack,
                    onPressed: context.pop,
                  ),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.inboxTitle,
                      style: AppTextStyles.screenTitle.copyWith(
                        color: colors.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s40),
                child: Text(
                  l10n.inboxEmpty,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyM.copyWith(color: colors.text2),
                ),
              )
            else
              SettingsCard(
                children: [
                  for (final entry in entries)
                    SettingsRow(
                      icon: _icon(entry.kind),
                      title: entry.title,
                      subtitle: entry.body,
                      trailing: Text(
                        _time(entry.at, l10n),
                        style: AppTextStyles.tabular(AppTextStyles.caption)
                            .copyWith(color: colors.text3),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime at, AppLocalizations l10n) {
    final now = ref.read(clockProvider)();
    final local = at.toLocal();
    final sameDay = DateUtils.isSameDay(local, now);
    return sameDay
        ? l10n.clockTime(local)
        : '${DateFormat.MMMd(l10n.localeName).format(local)} '
              '${l10n.clockTime(local)}';
  }

  static IconData _icon(NotificationKind kind) => switch (kind) {
    NotificationKind.stamina => LucideIcons.zap,
    NotificationKind.expeditions => LucideIcons.compass,
    NotificationKind.currency => LucideIcons.coins,
    NotificationKind.transformer => LucideIcons.repeat,
    NotificationKind.endgameReset => LucideIcons.trophy,
    NotificationKind.dailyReminder => LucideIcons.listChecks,
    NotificationKind.checkInResult => LucideIcons.calendarCheck,
    NotificationKind.cookieExpired => LucideIcons.cookie,
    NotificationKind.newCodes => LucideIcons.ticket,
    NotificationKind.newEvents => LucideIcons.calendarDays,
    NotificationKind.eventEnding => LucideIcons.hourglass,
  };
}
