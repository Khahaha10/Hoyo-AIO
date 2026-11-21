import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/app/router/app_router.dart';
import 'package:hoyo_aio/app/router/deep_link.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/logging/app_logger.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/has_accounts_provider.dart';
import 'package:hoyo_aio/features/background/presentation/providers/background_sync_provider.dart';
import 'package:hoyo_aio/features/codes/data/codes_repository_impl.dart';
import 'package:hoyo_aio/features/codes/presentation/code_format.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/providers/widget_sync_provider.dart';
import 'package:hoyo_aio/features/notifications/data/notification_service.dart';
import 'package:hoyo_aio/features/notifications/presentation/providers/notification_sync_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

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
  StreamSubscription<String?>? _taps;

  @override
  void initState() {
    super.initState();
    final service = ref.read(notificationServiceProvider);
    _taps = service.taps.listen((payload) => unawaited(_handleTap(payload)));
    unawaited(_handleLaunch(service));
  }

  @override
  void dispose() {
    unawaited(_taps?.cancel());
    super.dispose();
  }

  Future<void> _handleLaunch(NotificationService service) async {
    final payload = await service.launchPayload();
    if (payload == null) return;
    await ref.read(hasAccountsProvider.future);
    await _handleTap(payload);
  }

  Future<void> _handleTap(String? payload) async {
    if (parseCodePayload(payload) case (final game, final code)) {
      await Clipboard.setData(ClipboardData(text: code));
      await ref.read(codesRepositoryProvider).markRedeemed(game, code);
      await launchUrl(
        redeemUri(game, code),
        mode: LaunchMode.externalApplication,
      );
      return;
    }
    final uri = payload == null ? null : Uri.tryParse(payload);
    if (uri == null || !DeepLink.isDeepLink(uri) || !mounted) return;
    ref.read(appRouterProvider).go(DeepLink.toLocation(uri));
  }

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
