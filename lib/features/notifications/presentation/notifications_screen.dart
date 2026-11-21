import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_toggle.dart';
import 'package:hoyo_aio/core/design_system/components/settings_row.dart';
import 'package:hoyo_aio/core/design_system/components/time_pill.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/background/presentation/background_card.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:hoyo_aio/features/notifications/data/notification_settings_repository_impl.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_settings.dart';
import 'package:hoyo_aio/features/notifications/presentation/notification_permission_banner.dart';
import 'package:hoyo_aio/features/notifications/presentation/providers/notification_permission_provider.dart';
import 'package:hoyo_aio/features/notifications/presentation/providers/notification_sync_provider.dart';
import 'package:hoyo_aio/features/notifications/presentation/widgets/stamina_threshold_row.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

String minutesLabel(AppLocalizations l10n, int minutes) =>
    l10n.clockTime(DateTime(0).add(Duration(minutes: minutes)));

Future<int?> pickMinutes(BuildContext context, int minutes) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(
      hour: minutes ~/ TimeOfDay.minutesPerHour,
      minute: minutes % TimeOfDay.minutesPerHour,
    ),
  );
  if (picked == null) return null;
  return picked.hour * TimeOfDay.minutesPerHour + picked.minute;
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider).value;
    final l10n = context.l10n;
    final repository = ref.read(notificationSettingsRepositoryProvider);
    void save(NotificationSettings next) => unawaited(repository.save(next));
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
                      l10n.notificationsTitle,
                      style: AppTextStyles.screenTitle.copyWith(
                        color: context.colors.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            if (settings != null) ...[
              if (settings.enabled) const NotificationPermissionBanner(),
              SettingsCard(
                children: [
                  SettingsRow(
                    icon: LucideIcons.bell,
                    title: l10n.notificationsAllow,
                    subtitle: l10n.notificationsAllowBody,
                    trailing: AppToggle(
                      value: settings.enabled,
                      semanticLabel: l10n.notificationsAllow,
                      onChanged: (enabled) {
                        save(settings.copyWith(enabled: enabled));
                        if (enabled) {
                          unawaited(
                            ref
                                .read(notificationPermissionProvider.notifier)
                                .request(),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              _SectionLabel(l10n.notificationsAlertsSection),
              _AlertsCard(settings: settings, onChanged: save),
              const SizedBox(height: AppSpacing.s16),
              _QuietHoursCard(settings: settings, onChanged: save),
              _SectionLabel(l10n.backgroundSection),
              const BackgroundCard(),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.settings, required this.onChanged});

  final NotificationSettings settings;
  final ValueChanged<NotificationSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final active = settings.enabled;
    AppToggle toggle(
      String label, {
      required bool value,
      required ValueChanged<bool> onSet,
    }) => AppToggle(
      value: value,
      semanticLabel: label,
      onChanged: active ? onSet : null,
    );
    return SettingsCard(
      children: [
        Column(
          children: [
            SettingsRow(
              icon: LucideIcons.zap,
              title: l10n.notificationsStamina,
              subtitle: l10n.notificationsStaminaBody,
              trailing: toggle(
                l10n.notificationsStamina,
                value: settings.stamina,
                onSet: (v) => onChanged(settings.copyWith(stamina: v)),
              ),
            ),
            if (settings.stamina)
              StaminaThresholdRow(
                percent: settings.staminaThresholdPercent,
                onChanged: active
                    ? (percent) => onChanged(
                        settings.copyWith(staminaThresholdPercent: percent),
                      )
                    : null,
              ),
          ],
        ),
        SettingsRow(
          icon: LucideIcons.compass,
          title: l10n.notificationsExpeditions,
          subtitle: l10n.notificationsExpeditionsBody,
          trailing: toggle(
            l10n.notificationsExpeditions,
            value: settings.expeditions,
            onSet: (v) => onChanged(settings.copyWith(expeditions: v)),
          ),
        ),
        SettingsRow(
          icon: LucideIcons.coins,
          title: l10n.notificationsCurrency,
          subtitle: l10n.notificationsGenshinOnly,
          trailing: toggle(
            l10n.notificationsCurrency,
            value: settings.currency,
            onSet: (v) => onChanged(settings.copyWith(currency: v)),
          ),
        ),
        SettingsRow(
          icon: LucideIcons.arrowLeftRight,
          title: l10n.notificationsTransformer,
          subtitle: l10n.notificationsGenshinOnly,
          trailing: toggle(
            l10n.notificationsTransformer,
            value: settings.transformer,
            onSet: (v) => onChanged(settings.copyWith(transformer: v)),
          ),
        ),
        SettingsRow(
          icon: LucideIcons.listChecks,
          title: l10n.notificationsDailyReminder,
          subtitle: l10n.notificationsDailyReminderBody,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.s8,
            children: [
              TimePill(
                label: minutesLabel(l10n, settings.dailyReminderMinutes),
                semanticLabel: l10n.notificationsTimeSemantics(
                  l10n.notificationsDailyReminder,
                  minutesLabel(l10n, settings.dailyReminderMinutes),
                ),
                onTap: active ? () => unawaited(_pickReminder(context)) : null,
              ),
              toggle(
                l10n.notificationsDailyReminder,
                value: settings.dailyReminder,
                onSet: (v) => onChanged(settings.copyWith(dailyReminder: v)),
              ),
            ],
          ),
        ),
        SettingsRow(
          icon: LucideIcons.check,
          title: l10n.notificationsCheckIn,
          subtitle: l10n.notificationsCheckInBody,
          trailing: toggle(
            l10n.notificationsCheckIn,
            value: settings.checkInResult,
            onSet: (v) => onChanged(settings.copyWith(checkInResult: v)),
          ),
        ),
        SettingsRow(
          icon: LucideIcons.ticket,
          title: l10n.notificationsCodes,
          subtitle: l10n.notificationsCodesBody,
          trailing: toggle(
            l10n.notificationsCodes,
            value: settings.codes,
            onSet: (v) => onChanged(settings.copyWith(codes: v)),
          ),
        ),
        SettingsRow(
          icon: LucideIcons.calendarDays,
          title: l10n.notificationsEvents,
          subtitle: l10n.notificationsEventsBody,
          trailing: toggle(
            l10n.notificationsEvents,
            value: settings.events,
            onSet: (v) => onChanged(settings.copyWith(events: v)),
          ),
        ),
        SettingsRow(
          icon: LucideIcons.cookie,
          title: l10n.notificationsCookieExpired,
          subtitle: l10n.notificationsAlwaysOn,
          trailing: AppToggle(
            value: true,
            onChanged: null,
            semanticLabel: l10n.notificationsCookieExpired,
          ),
        ),
      ],
    );
  }

  Future<void> _pickReminder(BuildContext context) async {
    final minutes = await pickMinutes(context, settings.dailyReminderMinutes);
    if (minutes == null) return;
    onChanged(settings.copyWith(dailyReminderMinutes: minutes));
  }
}

class _QuietHoursCard extends StatelessWidget {
  const _QuietHoursCard({required this.settings, required this.onChanged});

  final NotificationSettings settings;
  final ValueChanged<NotificationSettings> onChanged;

  Future<void> _pick(BuildContext context) async {
    final start = await pickMinutes(context, settings.quietStartMinutes);
    if (start == null || !context.mounted) return;
    final end = await pickMinutes(context, settings.quietEndMinutes);
    if (end == null) return;
    onChanged(
      settings.copyWith(quietStartMinutes: start, quietEndMinutes: end),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final active = settings.enabled;
    return SettingsCard(
      children: [
        SettingsRow(
          icon: LucideIcons.moon,
          title: l10n.notificationsQuietHours,
          subtitle: l10n.notificationsQuietRange(
            minutesLabel(l10n, settings.quietStartMinutes),
            minutesLabel(l10n, settings.quietEndMinutes),
          ),
          onTap: active ? () => unawaited(_pick(context)) : null,
          trailing: AppToggle(
            value: settings.quietHours,
            semanticLabel: l10n.notificationsQuietHours,
            onChanged: active
                ? (v) => onChanged(settings.copyWith(quietHours: v))
                : null,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.s4,
      AppSpacing.s24,
      AppSpacing.s4,
      AppSpacing.s8,
    ),
    child: Text(
      text.toUpperCase(),
      style: AppTextStyles.overline.copyWith(color: context.colors.text2),
    ),
  );
}
