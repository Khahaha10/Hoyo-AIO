import 'package:hoyo_aio/app/app_settings_provider.dart';
import 'package:hoyo_aio/core/l10n/resolve_l10n.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/selected_role_provider.dart';
import 'package:hoyo_aio/features/checkin/data/check_in_history_repository_impl.dart';
import 'package:hoyo_aio/features/checkin/presentation/providers/check_in_provider.dart';
import 'package:hoyo_aio/features/dashboard/data/notes_repository_impl.dart';
import 'package:hoyo_aio/features/home_widgets/data/home_widget_bridge_impl.dart';
import 'package:hoyo_aio/features/home_widgets/data/widget_config_repository_impl.dart';
import 'package:hoyo_aio/features/home_widgets/data/widget_labels.dart';
import 'package:hoyo_aio/features/home_widgets/domain/update_home_widgets.dart';
import 'package:hoyo_aio/features/notifications/presentation/providers/notification_sync_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'widget_sync_provider.g.dart';

@Riverpod(keepAlive: true)
UpdateHomeWidgets updateHomeWidgets(Ref ref) => UpdateHomeWidgets(
  ref.watch(notesRepositoryProvider),
  ref.watch(checkInHistoryRepositoryProvider),
  ref.watch(widgetConfigRepositoryProvider),
  ref.watch(homeWidgetBridgeProvider),
  ref.watch(clockProvider),
);

@Riverpod(keepAlive: true)
Future<int> widgetSync(Ref ref) async {
  final roles = ref.watch(dashboardRolesProvider);
  final checkIn = ref.watch(autoCheckInSettingsProvider).value;
  final gamesWithRoles = ref.watch(checkInGamesProvider).toSet();
  ref
    ..watch(noteSnapshotVersionProvider)
    ..watch(checkInRunsProvider);
  final locale = ref.watch(appPreferencesProvider).value?.locale;
  if (checkIn == null) return 0;
  final snapshot = await ref.read(updateHomeWidgetsProvider)(
    roles: roles,
    checkInGames: checkIn.games.intersection(gamesWithRoles),
    labels: widgetLabels(resolveL10n(locale?.languageCode)),
  );
  return snapshot.roles.length;
}
