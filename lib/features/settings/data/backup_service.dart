import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:file_selector/file_selector.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/settings/domain/backup_schema.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'backup_service.g.dart';

@riverpod
BackupService backupService(Ref ref) =>
    BackupService(ref.watch(appDatabaseProvider), ref.watch(clockProvider));

class BackupImportResult {
  const BackupImportResult({required this.needsLogin});

  final int needsLogin;
}

class BackupService {
  const BackupService(this._db, this._clock);

  static const _typeGroup = XTypeGroup(
    label: 'JSON',
    extensions: ['json'],
    mimeTypes: ['application/json'],
    uniformTypeIdentifiers: ['public.json'],
  );

  final AppDatabase _db;
  final Clock _clock;

  Future<void> export() async {
    final data = await read();
    final day = data.exportedAt.toIso8601String().substring(0, 10);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            utf8.encode(data.encode()),
            mimeType: 'application/json',
          ),
        ],
        fileNameOverrides: ['hoyo_aio_backup_$day.json'],
      ),
    );
  }

  Future<BackupData?> pick() async {
    final file = await openFile(acceptedTypeGroups: const [_typeGroup]);
    if (file == null) return null;
    if (await file.length() > BackupData.maxBytes) {
      throw const BackupFormatException('size');
    }
    return BackupData.decode(await file.readAsString());
  }

  Future<BackupData> read() async {
    final settings = await _db.select(_db.appSettings).getSingle();
    final accounts = await _db.select(_db.accounts).get();
    final roles = await _db.select(_db.gameRoles).get();
    final widgets = await _db.select(_db.widgetConfigs).get();
    final rolesById = {for (final role in roles) role.id: role};
    return BackupData(
      exportedAt: _clock(),
      settings: BackupSettings(
        themeMode: settings.themeMode,
        dynamicColor: settings.dynamicColor,
        accent: settings.accent,
        localeCode: settings.localeCode,
        autoCheckInMinutes: settings.autoCheckInMinutes,
        autoCheckInGames: [
          for (final name in settings.autoCheckInGames.split(','))
            ?Game.values.asNameMap()[name],
        ],
        notificationSettings: switch (_tryDecode(
          settings.notificationSettings,
        )) {
          final Map<String, Object?> map => map,
          _ => const {},
        },
        refreshIntervalMinutes: settings.refreshIntervalMinutes,
      ),
      accounts: [
        for (final account in accounts)
          BackupAccount(
            id: account.id,
            nickname: account.nickname,
            roles: [
              for (final role in roles)
                if (role.accountId == account.id)
                  BackupRole(
                    game: role.game,
                    uid: role.uid,
                    server: role.server,
                    nickname: role.nickname,
                    level: role.level,
                    enabled: role.enabled,
                  ),
            ],
          ),
      ],
      widgets: [
        for (final widget in widgets)
          BackupWidget(
            widgetId: widget.widgetId,
            size: widget.size,
            accountId: widget.accountId,
            roleGame: rolesById[widget.roleId]?.game,
            roleUid: rolesById[widget.roleId]?.uid,
            theme: widget.theme,
            opacity: widget.opacity,
            accent: widget.accent,
            fontSize: widget.fontSize,
            visibleItems: switch (_tryDecode(widget.visibleItems)) {
              final List<Object?> items => [...items.whereType<String>()],
              _ => const [],
            },
          ),
      ],
    );
  }

  Future<BackupImportResult> apply(BackupData data) =>
      _db.transaction(() async {
        await _applySettings(data.settings);
        var needsLogin = 0;
        for (final account in data.accounts) {
          if (await _insertAccountIfMissing(account)) needsLogin++;
          for (final role in account.roles) {
            await _upsertRole(account.id, role);
          }
        }
        for (final widget in data.widgets) {
          await _upsertWidget(widget);
        }
        return BackupImportResult(needsLogin: needsLogin);
      });

  Future<void> _applySettings(BackupSettings settings) =>
      (_db.update(_db.appSettings)..where((s) => s.id.equals(1))).write(
        AppSettingsCompanion(
          themeMode: Value(settings.themeMode),
          dynamicColor: Value(settings.dynamicColor),
          accent: Value(settings.accent),
          localeCode: Value(settings.localeCode),
          autoCheckInMinutes: Value(settings.autoCheckInMinutes),
          autoCheckInGames: Value(
            settings.autoCheckInGames.map((game) => game.name).join(','),
          ),
          notificationSettings: Value(
            jsonEncode(settings.notificationSettings),
          ),
          refreshIntervalMinutes: Value(settings.refreshIntervalMinutes),
        ),
      );

  Future<bool> _insertAccountIfMissing(BackupAccount account) async {
    final existing = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(account.id))).getSingleOrNull();
    if (existing != null) return false;
    final now = _clock();
    await _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: account.id,
            nickname: account.nickname,
            status: AccountStatus.needsLogin,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return true;
  }

  Future<void> _upsertRole(String accountId, BackupRole role) => _db
      .into(_db.gameRoles)
      .insert(
        GameRolesCompanion.insert(
          accountId: accountId,
          game: role.game,
          uid: role.uid,
          server: role.server,
          nickname: role.nickname,
          level: role.level,
          enabled: Value(role.enabled),
        ),
        onConflict: DoUpdate(
          (_) => GameRolesCompanion(
            server: Value(role.server),
            nickname: Value(role.nickname),
            level: Value(role.level),
            enabled: Value(role.enabled),
          ),
          target: [
            _db.gameRoles.accountId,
            _db.gameRoles.game,
            _db.gameRoles.uid,
          ],
        ),
      );

  Future<void> _upsertWidget(BackupWidget widget) async {
    final account = switch (widget.accountId) {
      final id? => await (_db.select(
        _db.accounts,
      )..where((a) => a.id.equals(id))).getSingleOrNull(),
      null => null,
    };
    final role = switch ((account, widget.roleGame, widget.roleUid)) {
      (final account?, final game?, final uid?) =>
        await (_db.select(_db.gameRoles)..where(
              (r) =>
                  r.accountId.equals(account.id) &
                  r.game.equalsValue(game) &
                  r.uid.equals(uid),
            ))
            .getSingleOrNull(),
      _ => null,
    };
    await _db
        .into(_db.widgetConfigs)
        .insertOnConflictUpdate(
          WidgetConfigsCompanion.insert(
            widgetId: Value(widget.widgetId),
            size: widget.size,
            accountId: Value(account?.id),
            roleId: Value(role?.id),
            theme: widget.theme,
            opacity: Value(widget.opacity),
            accent: Value(widget.accent),
            fontSize: widget.fontSize,
            visibleItems: Value(jsonEncode(widget.visibleItems)),
            updatedAt: _clock(),
          ),
        );
  }

  static Object? _tryDecode(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }
}
