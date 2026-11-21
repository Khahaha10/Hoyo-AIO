import 'dart:convert';

import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';

class BackupFormatException implements Exception {
  const BackupFormatException(this.reason);

  final String reason;

  @override
  String toString() => 'BackupFormatException: $reason';
}

class BackupSettings {
  const BackupSettings({
    required this.themeMode,
    required this.dynamicColor,
    required this.accent,
    required this.localeCode,
    required this.autoCheckInMinutes,
    required this.autoCheckInGames,
    required this.notificationSettings,
    required this.refreshIntervalMinutes,
  });

  final AppThemeMode themeMode;
  final bool dynamicColor;
  final String accent;
  final String? localeCode;
  final int autoCheckInMinutes;
  final List<Game> autoCheckInGames;
  final Map<String, Object?> notificationSettings;
  final int refreshIntervalMinutes;

  Map<String, Object?> toJson() => {
    'themeMode': themeMode.name,
    'dynamicColor': dynamicColor,
    'accent': accent,
    'localeCode': localeCode,
    'autoCheckInMinutes': autoCheckInMinutes,
    'autoCheckInGames': [for (final game in autoCheckInGames) game.name],
    'notificationSettings': notificationSettings,
    'refreshIntervalMinutes': refreshIntervalMinutes,
  };

  static BackupSettings fromJson(Object? json) => switch (json) {
    {
      'themeMode': final Object? themeMode,
      'dynamicColor': final bool dynamicColor,
      'accent': final String accent,
      'localeCode': final String? localeCode,
      'autoCheckInMinutes': final int autoCheckInMinutes,
      'autoCheckInGames': final List<Object?> games,
      'notificationSettings': final Map<String, Object?> notifications,
      'refreshIntervalMinutes': final int refreshIntervalMinutes,
    }
        when autoCheckInMinutes >= 0 &&
            autoCheckInMinutes < Duration.minutesPerDay &&
            refreshIntervalMinutes >= minRefreshMinutes =>
      BackupSettings(
        themeMode: _enum(AppThemeMode.values, themeMode),
        dynamicColor: dynamicColor,
        accent: accent,
        localeCode: localeCode,
        autoCheckInMinutes: autoCheckInMinutes,
        autoCheckInGames: [for (final game in games) _enum(Game.values, game)],
        notificationSettings: notifications,
        refreshIntervalMinutes: refreshIntervalMinutes,
      ),
    _ => throw const BackupFormatException('settings'),
  };

  static const minRefreshMinutes = 15;
}

class BackupRole {
  const BackupRole({
    required this.game,
    required this.uid,
    required this.server,
    required this.nickname,
    required this.level,
    required this.enabled,
  });

  final Game game;
  final String uid;
  final String server;
  final String nickname;
  final int level;
  final bool enabled;

  Map<String, Object?> toJson() => {
    'game': game.name,
    'uid': uid,
    'server': server,
    'nickname': nickname,
    'level': level,
    'enabled': enabled,
  };

  static BackupRole fromJson(Object? json) => switch (json) {
    {
      'game': final Object? game,
      'uid': final String uid,
      'server': final String server,
      'nickname': final String nickname,
      'level': final int level,
      'enabled': final bool enabled,
    }
        when uid.isNotEmpty =>
      BackupRole(
        game: _enum(Game.values, game),
        uid: uid,
        server: server,
        nickname: nickname,
        level: level,
        enabled: enabled,
      ),
    _ => throw const BackupFormatException('role'),
  };
}

class BackupAccount {
  const BackupAccount({
    required this.id,
    required this.nickname,
    required this.roles,
  });

  final String id;
  final String nickname;
  final List<BackupRole> roles;

  Map<String, Object?> toJson() => {
    'id': id,
    'nickname': nickname,
    'roles': [for (final role in roles) role.toJson()],
  };

  static BackupAccount fromJson(Object? json) => switch (json) {
    {
      'id': final String id,
      'nickname': final String nickname,
      'roles': final List<Object?> roles,
    }
        when id.isNotEmpty =>
      BackupAccount(
        id: id,
        nickname: nickname,
        roles: [for (final role in roles) BackupRole.fromJson(role)],
      ),
    _ => throw const BackupFormatException('account'),
  };
}

class BackupWidget {
  const BackupWidget({
    required this.widgetId,
    required this.size,
    required this.accountId,
    required this.roleGame,
    required this.roleUid,
    required this.theme,
    required this.opacity,
    required this.accent,
    required this.fontSize,
    required this.visibleItems,
  });

  final int widgetId;
  final WidgetSize size;
  final String? accountId;
  final Game? roleGame;
  final String? roleUid;
  final WidgetTheme theme;
  final double opacity;
  final String accent;
  final WidgetFontSize fontSize;
  final List<String> visibleItems;

  Map<String, Object?> toJson() => {
    'widgetId': widgetId,
    'size': size.name,
    'accountId': accountId,
    'roleGame': roleGame?.name,
    'roleUid': roleUid,
    'theme': theme.name,
    'opacity': opacity,
    'accent': accent,
    'fontSize': fontSize.name,
    'visibleItems': visibleItems,
  };

  static BackupWidget fromJson(Object? json) => switch (json) {
    {
      'widgetId': final int widgetId,
      'size': final Object? size,
      'accountId': final String? accountId,
      'roleGame': final Object? roleGame,
      'roleUid': final String? roleUid,
      'theme': final Object? theme,
      'opacity': final num opacity,
      'accent': final String accent,
      'fontSize': final Object? fontSize,
      'visibleItems': final List<Object?> items,
    }
        when opacity >= 0 && opacity <= 1 =>
      BackupWidget(
        widgetId: widgetId,
        size: _enum(WidgetSize.values, size),
        accountId: accountId,
        roleGame: roleGame == null ? null : _enum(Game.values, roleGame),
        roleUid: roleUid,
        theme: _enum(WidgetTheme.values, theme),
        opacity: opacity.toDouble(),
        accent: accent,
        fontSize: _enum(WidgetFontSize.values, fontSize),
        visibleItems: [
          for (final item in items)
            if (item is String)
              item
            else
              throw const BackupFormatException('item'),
        ],
      ),
    _ => throw const BackupFormatException('widget'),
  };
}

class BackupData {
  const BackupData({
    required this.exportedAt,
    required this.settings,
    required this.accounts,
    required this.widgets,
  });

  static const appId = 'hoyo_aio';
  static const version = 1;
  static const maxBytes = 1024 * 1024;

  final DateTime exportedAt;
  final BackupSettings settings;
  final List<BackupAccount> accounts;
  final List<BackupWidget> widgets;

  String encode() => const JsonEncoder.withIndent('  ').convert({
    'app': appId,
    'version': version,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'settings': settings.toJson(),
    'accounts': [for (final account in accounts) account.toJson()],
    'widgets': [for (final widget in widgets) widget.toJson()],
  });

  static BackupData decode(String text) {
    if (text.length > maxBytes) throw const BackupFormatException('size');
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      throw const BackupFormatException('json');
    }
    return switch (json) {
      {
        'app': appId,
        'version': version,
        'exportedAt': final String exportedAt,
        'settings': final Object? settings,
        'accounts': final List<Object?> accounts,
        'widgets': final List<Object?> widgets,
      } =>
        BackupData(
          exportedAt:
              DateTime.tryParse(exportedAt) ??
              (throw const BackupFormatException('exportedAt')),
          settings: BackupSettings.fromJson(settings),
          accounts: [for (final a in accounts) BackupAccount.fromJson(a)],
          widgets: [for (final w in widgets) BackupWidget.fromJson(w)],
        ),
      {'app': appId, 'version': final int other} when other > version =>
        throw const BackupFormatException('newerVersion'),
      _ => throw const BackupFormatException('notBackup'),
    };
  }
}

T _enum<T extends Enum>(List<T> values, Object? name) =>
    values.asNameMap()[name] ?? (throw BackupFormatException('enum $name'));
