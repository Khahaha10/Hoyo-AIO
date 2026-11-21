import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/l10n/game_labels.dart';
import 'package:hoyo_aio/core/logging/app_logger.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/accounts/data/account_repository_impl.dart';
import 'package:hoyo_aio/features/accounts/domain/account_summary.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/selected_role_provider.dart';
import 'package:hoyo_aio/features/checkin/data/check_in_history_repository_impl.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_record.dart';
import 'package:hoyo_aio/features/checkin/domain/run_auto_checkin.dart';
import 'package:hoyo_aio/features/checkin/presentation/providers/check_in_provider.dart';
import 'package:hoyo_aio/features/dashboard/data/notes_repository_impl.dart';
import 'package:hoyo_aio/features/notifications/data/notification_scheduler_impl.dart';
import 'package:hoyo_aio/features/notifications/data/notification_service.dart';
import 'package:hoyo_aio/features/notifications/data/notification_settings_repository_impl.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_kind.dart';
import 'package:hoyo_aio/features/notifications/presentation/providers/notification_sync_provider.dart';

class BackgroundJobs {
  const BackgroundJobs(this._container);

  static const checkInResultId = 2;
  static const _cookieIdBase = 100000;
  static const _cookieIdRange = 100000;

  final ProviderContainer _container;

  Future<List<AccountSummary>> _accounts() =>
      _container.read(accountRepositoryProvider).watchAccounts().first;

  Future<void> refreshNotes() async {
    final before = await _accounts();
    final notes = _container.read(notesRepositoryProvider);
    for (final account in before) {
      if (account.needsAttention) continue;
      for (final role in account.enabledRoles) {
        if (!dashboardGames.contains(role.game)) continue;
        try {
          await notes.refresh(role);
        } on AppException catch (error) {
          _container
              .read(appLoggerProvider)
              .warning(
                'background refresh ${role.game.name}: ${error.runtimeType}',
              );
        }
      }
    }
    await _checkInIfDue();
    await _afterJob(before);
  }

  Future<void> autoCheckIn() async {
    final before = await _accounts();
    await _checkInIfDue(force: true);
    await _afterJob(before);
  }

  Future<Duration?> nextAutoCheckInDelay() async {
    final settings = await _container
        .read(checkInHistoryRepositoryProvider)
        .watchSettings()
        .first;
    if (settings.games.isEmpty) return null;
    final now = _container.read(clockProvider)();
    return settings.nextRunAfter(now).difference(now);
  }

  Future<void> _checkInIfDue({bool force = false}) async {
    final history = _container.read(checkInHistoryRepositoryProvider);
    final settings = await history.watchSettings().first;
    if (settings.games.isEmpty) return;
    final now = _container.read(clockProvider)();
    final dueToday = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(minutes: settings.runAtMinutes));
    if (!force && now.isBefore(dueToday)) return;
    if (await history.hasRunOn(RunAutoCheckIn.dayKey(now))) return;
    final accounts = await _accounts();
    final roles = [
      for (final account in accounts)
        if (!account.needsAttention) ...account.enabledRoles,
    ];
    final run = await _container.read(runAutoCheckInProvider)(
      roles: roles,
      games: settings.games,
    );
    await _notifyCheckInFailures(run);
  }

  Future<void> _afterJob(List<AccountSummary> before) async {
    final after = await _accounts();
    await _notifyNewlyExpired(before, after);
    await _reschedule(after);
  }

  Future<String?> _localeCode() async {
    final db = _container.read(appDatabaseProvider);
    final row = await (db.select(
      db.appSettings,
    )..where((s) => s.id.equals(1))).getSingleOrNull();
    return row?.localeCode;
  }

  Future<void> _reschedule(List<AccountSummary> accounts) async {
    final settings = await _container
        .read(notificationSettingsRepositoryProvider)
        .read();
    final roles = <SavedRole>[
      for (final healthy in [true, false])
        for (final account in accounts)
          if (account.needsAttention != healthy)
            for (final role in account.enabledRoles)
              if (dashboardGames.contains(role.game)) role,
    ];
    await _container.read(rescheduleNotificationsProvider)(
      roles: roles,
      settings: settings,
      localeCode: await _localeCode(),
    );
  }

  Future<void> _notifyNewlyExpired(
    List<AccountSummary> before,
    List<AccountSummary> after,
  ) async {
    final settings = await _container
        .read(notificationSettingsRepositoryProvider)
        .read();
    if (!settings.enabled) return;
    final wasValid = {
      for (final account in before)
        if (account.status == AccountStatus.valid) account.id,
    };
    final l10n = NotificationSchedulerImpl.resolveL10n(await _localeCode());
    for (final account in after) {
      if (account.status != AccountStatus.expired) continue;
      if (!wasValid.contains(account.id)) continue;
      await _container
          .read(notificationServiceProvider)
          .showNow(
            id: _cookieIdBase + account.id.hashCode.abs() % _cookieIdRange,
            kind: NotificationKind.cookieExpired,
            title: l10n.notifyCookieExpiredTitle,
            body: l10n.notifyCookieExpiredBody(account.nickname),
          );
    }
  }

  Future<void> _notifyCheckInFailures(CheckInRun run) async {
    final failures = [
      for (final record in run.records)
        if (!record.isSuccess) record,
    ];
    if (failures.isEmpty) return;
    final settings = await _container
        .read(notificationSettingsRepositoryProvider)
        .read();
    if (!settings.enabled || !settings.checkInResult) return;
    final l10n = NotificationSchedulerImpl.resolveL10n(await _localeCode());
    await _container
        .read(notificationServiceProvider)
        .showNow(
          id: checkInResultId,
          kind: NotificationKind.checkInResult,
          title: l10n.notifyCheckInFailedTitle(failures.length),
          body: [for (final record in failures) l10n.gameShortName(record.game)]
              .join(' · '),
        );
  }
}
