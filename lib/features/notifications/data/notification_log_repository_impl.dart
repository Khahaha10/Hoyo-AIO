import 'package:drift/drift.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_kind.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_log_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_log_repository_impl.g.dart';

class NotificationLogRepositoryImpl implements NotificationLogRepository {
  const NotificationLogRepositoryImpl(this._db, this._clock);

  static const retention = Duration(days: 30);
  static const shownLimit = 100;

  final AppDatabase _db;
  final Clock _clock;

  @override
  Future<void> recordSent(NotificationLogEntry entry) =>
      _db.transaction(() async {
        await _prune();
        await _db.into(_db.notificationLog).insert(_companion(entry));
      });

  @override
  Future<void> replaceUpcoming(List<NotificationLogEntry> entries) {
    final now = _clock();
    return _db.transaction(() async {
      await (_db.delete(
        _db.notificationLog,
      )..where((row) => row.at.isBiggerThanValue(now))).go();
      await _prune();
      await _db.batch(
        (batch) => batch.insertAll(_db.notificationLog, [
          for (final entry in entries)
            if (entry.at.isAfter(now)) _companion(entry),
        ]),
      );
    });
  }

  @override
  Stream<List<NotificationLogEntry>> watchDelivered(DateTime now) =>
      (_db.select(_db.notificationLog)
            ..where((row) => row.at.isSmallerOrEqualValue(now))
            ..orderBy([(row) => OrderingTerm.desc(row.at)])
            ..limit(shownLimit))
          .watch()
          .map((rows) => [for (final row in rows) ?_entry(row)]);

  @override
  Future<void> markAllRead(DateTime now) =>
      (_db.update(
            _db.notificationLog,
          )..where((row) => row.at.isSmallerOrEqualValue(now) & row.read.not()))
          .write(const NotificationLogCompanion(read: Value(true)));

  Future<int> _prune() =>
      (_db.delete(_db.notificationLog)..where(
            (row) => row.at.isSmallerThanValue(_clock().subtract(retention)),
          ))
          .go();

  static NotificationLogCompanion _companion(NotificationLogEntry entry) =>
      NotificationLogCompanion.insert(
        kind: entry.kind.name,
        title: entry.title,
        body: entry.body,
        payload: Value(entry.payload),
        at: entry.at,
      );

  static NotificationLogEntry? _entry(NotificationLogRow row) {
    final kind = NotificationKind.values.asNameMap()[row.kind];
    if (kind == null) return null;
    return NotificationLogEntry(
      id: row.id,
      kind: kind,
      title: row.title,
      body: row.body,
      payload: row.payload,
      at: row.at,
      read: row.read,
    );
  }
}

@Riverpod(keepAlive: true)
NotificationLogRepository notificationLogRepository(Ref ref) =>
    NotificationLogRepositoryImpl(
      ref.watch(appDatabaseProvider),
      ref.watch(clockProvider),
    );
