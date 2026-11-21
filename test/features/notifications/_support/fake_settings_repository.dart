import 'dart:async';

import 'package:hoyo_aio/features/notifications/domain/notification_repositories.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_settings.dart';

class FakeNotificationSettingsRepository
    implements NotificationSettingsRepository {
  FakeNotificationSettingsRepository([
    this.current = const NotificationSettings(),
  ]);

  NotificationSettings current;
  final _changes = StreamController<NotificationSettings>.broadcast();
  final saved = <NotificationSettings>[];

  @override
  Stream<NotificationSettings> watch() async* {
    yield current;
    yield* _changes.stream;
  }

  @override
  Future<NotificationSettings> read() async => current;

  @override
  Future<void> save(NotificationSettings settings) async {
    current = settings;
    saved.add(settings);
    _changes.add(settings);
  }
}
