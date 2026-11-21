import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/logging/app_logger.dart';
import 'package:hoyo_aio/features/background/presentation/providers/background_sync_provider.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/providers/widget_sync_provider.dart';
import 'package:hoyo_aio/features/notifications/data/notification_service.dart';
import 'package:hoyo_aio/features/notifications/presentation/providers/notification_sync_provider.dart';
import 'package:material_ui/material_ui.dart';

class NotificationChannelsSync extends ConsumerStatefulWidget {
  const NotificationChannelsSync({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationChannelsSync> createState() =>
      _NotificationChannelsSyncState();
}

class _NotificationChannelsSyncState
    extends ConsumerState<NotificationChannelsSync> {
  String? _syncedLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = context.l10n;
    if (l10n.localeName == _syncedLocale) return;
    _syncedLocale = l10n.localeName;
    unawaited(ref.read(notificationServiceProvider).syncChannels(l10n));
  }

  @override
  Widget build(BuildContext context) {
    void logError(String name, AsyncValue<Object?> next) {
      if (next case AsyncError(:final error)) {
        ref.read(appLoggerProvider).warning('$name failed: $error');
      }
    }

    ref
      ..listen(notificationSyncProvider, (_, next) => logError('alerts', next))
      ..listen(backgroundSyncProvider, (_, next) => logError('jobs', next))
      ..listen(widgetSyncProvider, (_, next) => logError('widgets', next));
    return widget.child;
  }
}
