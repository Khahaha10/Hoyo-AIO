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
  IntColumn get refreshIntervalMinutes =>
      integer().withDefault(const Constant(30))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
