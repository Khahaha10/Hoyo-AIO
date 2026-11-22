import 'package:hoyo_aio/features/notifications/domain/notification_kind.dart';

class NotificationLogEntry {
  const NotificationLogEntry({
    required this.kind,
    required this.title,
    required this.body,
    required this.at,
    this.payload,
    this.id = 0,
    this.read = false,
  });

  final int id;
  final NotificationKind kind;
  final String title;
  final String body;
  final String? payload;
  final DateTime at;
  final bool read;
}

abstract interface class NotificationLogRepository {
  Future<void> recordSent(NotificationLogEntry entry);

  Future<void> replaceUpcoming(List<NotificationLogEntry> entries);

  Stream<List<NotificationLogEntry>> watchDelivered(DateTime now);

  Future<void> markAllRead(DateTime now);
}
