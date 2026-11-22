import 'package:drift/drift.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get nickname => text()();
  TextColumn get status => textEnum<AccountStatus>()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(name: 'game_roles_account', columns: {#accountId})
class GameRoles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.cascade)();
  TextColumn get game => textEnum<Game>()();
  TextColumn get uid => text()();
  TextColumn get server => text()();
  TextColumn get nickname => text()();
  IntColumn get level => integer()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {accountId, game, uid},
  ];
}

class NoteSnapshots extends Table {
  IntColumn get roleId =>
      integer().references(GameRoles, #id, onDelete: KeyAction.cascade)();
  TextColumn get game => textEnum<Game>()();
  TextColumn get payload => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {roleId};
}

@TableIndex(name: 'checkin_history_account_day', columns: {#accountId, #day})
class CheckInHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.cascade)();
  TextColumn get game => textEnum<Game>()();
  TextColumn get day => text()();
  TextColumn get result => textEnum<CheckInResult>()();
  TextColumn get reward => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class WidgetConfigs extends Table {
  IntColumn get widgetId => integer()();
  TextColumn get size => textEnum<WidgetSize>()();
  TextColumn get accountId => text().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get roleId => integer().nullable().references(
    GameRoles,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get theme => textEnum<WidgetTheme>()();
  RealColumn get opacity => real().withDefault(const Constant(0.8))();
  TextColumn get accent => text().withDefault(const Constant('match'))();
  TextColumn get fontSize => textEnum<WidgetFontSize>()();
  TextColumn get visibleItems => text().withDefault(const Constant('[]'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {widgetId};
}

class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get themeMode => textEnum<AppThemeMode>().withDefault(
    Constant(AppThemeMode.system.name),
  )();
  BoolColumn get dynamicColor => boolean().withDefault(const Constant(false))();
  TextColumn get accent => text().withDefault(const Constant('lime'))();
  TextColumn get localeCode => text().nullable()();
  BoolColumn get onboardingSeen =>
      boolean().withDefault(const Constant(false))();
  IntColumn get autoCheckInMinutes =>
      integer().withDefault(const Constant(20 * 60))();
  TextColumn get autoCheckInGames =>
      text().withDefault(const Constant('genshin,starRail,zzz,hi3'))();
  TextColumn get notificationSettings =>
      text().withDefault(const Constant('{}'))();
  IntColumn get refreshIntervalMinutes =>
      integer().withDefault(const Constant(30))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SeenCodes extends Table {
  TextColumn get game => textEnum<Game>()();
  TextColumn get code => text()();
  TextColumn get rewards => text().withDefault(const Constant('[]'))();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get firstSeenAt => dateTime()();
  DateTimeColumn get readAt => dateTime().nullable()();
  DateTimeColumn get redeemedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {game, code};
}

class SeenEvents extends Table {
  TextColumn get id => text()();
  TextColumn get game => textEnum<Game>()();
  TextColumn get name => text()();
  TextColumn get summary => text().withDefault(const Constant(''))();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime()();
  TextColumn get webPath => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  BoolColumn get remind => boolean().withDefault(const Constant(false))();
  DateTimeColumn get firstSeenAt => dateTime()();
  DateTimeColumn get readAt => dateTime().nullable()();
  DateTimeColumn get endingNotifiedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('GachaRecordRow')
@TableIndex(name: 'gacha_records_banner', columns: {#game, #uid, #banner})
class GachaRecords extends Table {
  TextColumn get game => textEnum<Game>()();
  IntColumn get id => integer()();
  TextColumn get uid => text()();
  TextColumn get banner => text()();
  TextColumn get gachaType => text()();
  TextColumn get name => text()();
  TextColumn get itemType => text()();
  IntColumn get rank => integer()();
  TextColumn get time => text()();

  @override
  Set<Column<Object>> get primaryKey => {game, id};
}

@DataClassName('NotificationLogRow')
@TableIndex(name: 'notification_log_at', columns: {#at})
class NotificationLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get payload => text().nullable()();
  DateTimeColumn get at => dateTime()();
  BoolColumn get read => boolean().withDefault(const Constant(false))();
}

@DataClassName('ChronicleCacheRow')
class ChronicleCache extends Table {
  IntColumn get roleId =>
      integer().references(GameRoles, #id, onDelete: KeyAction.cascade)();
  TextColumn get key => text()();
  TextColumn get payload => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {roleId, key};
}
