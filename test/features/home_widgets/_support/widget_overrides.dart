import 'package:flutter_riverpod/misc.dart';
import 'package:hoyo_aio/app/app_settings_provider.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/selected_role_provider.dart';
import 'package:hoyo_aio/features/checkin/data/check_in_history_repository_impl.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_record.dart';
import 'package:hoyo_aio/features/checkin/presentation/providers/check_in_provider.dart';
import 'package:hoyo_aio/features/dashboard/data/notes_repository_impl.dart';
import 'package:hoyo_aio/features/dashboard/domain/note_result.dart';
import 'package:hoyo_aio/features/home_widgets/data/home_widget_bridge_impl.dart';
import 'package:hoyo_aio/features/home_widgets/data/widget_config_repository_impl.dart';
import 'package:hoyo_aio/features/home_widgets/domain/home_widget_repositories.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/providers/widget_sync_provider.dart';
import 'package:hoyo_aio/features/notifications/presentation/providers/notification_sync_provider.dart';
import 'package:material_ui/material_ui.dart';

import 'widget_fixtures.dart';

final widgetNow = fetchedAt.add(const Duration(minutes: 40));

List<Override> widgetOverrides({
  required HomeWidgetBridge bridge,
  WidgetConfigRepository? configs,
  List<SavedRole>? roles,
  Map<int, NoteResult>? notes,
  Locale? locale,
  bool withSettings = true,
}) => [
  dashboardRolesProvider.overrideWith(
    (_) => roles ?? [genshinRole, starRailRole, zzzRole],
  ),
  checkInGamesProvider.overrideWith(
    (_) => const [Game.genshin, Game.starRail, Game.zzz],
  ),
  autoCheckInSettingsProvider.overrideWith(
    (_) => withSettings
        ? Stream.value(
            const AutoCheckInSettings(
              games: {Game.genshin, Game.hi3},
              runAtMinutes: 60,
            ),
          )
        : const Stream.empty(),
  ),
  noteSnapshotVersionProvider.overrideWith((_) => Stream.value(0)),
  checkInRunsProvider.overrideWith((_) => Stream.value(const [])),
  appPreferencesProvider.overrideWith(
    (_) => Stream.value(
      AppPreferences(
        themeMode: ThemeMode.light,
        locale: locale ?? const Locale('en'),
        onboardingSeen: true,
      ),
    ),
  ),
  homeWidgetInteractivityProvider.overrideWith((_) async {}),
  notesRepositoryProvider.overrideWithValue(
    FakeNotesRepository(
      notes ?? {for (final (role, result) in allNotes) role.id: result},
    ),
  ),
  checkInHistoryRepositoryProvider.overrideWithValue(FakeCheckInHistory()),
  homeWidgetBridgeProvider.overrideWithValue(bridge),
  if (configs != null)
    widgetConfigRepositoryProvider.overrideWithValue(configs),
  clockProvider.overrideWithValue(() => widgetNow),
];
