import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/game_region.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio_provider.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';
import 'package:hoyo_aio/core/storage/cookie_vault.dart';
import 'package:hoyo_aio/core/storage/hoyolab_cookie.dart';
import 'package:hoyo_aio/features/accounts/data/dto/record_card_dto.dart';
import 'package:hoyo_aio/features/accounts/domain/account_repository.dart';
import 'package:hoyo_aio/features/accounts/domain/account_summary.dart';
import 'package:hoyo_aio/features/accounts/domain/detected_role.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_repository_impl.g.dart';

class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl(this._dio, this._db, this._vault);

  final Dio _dio;
  final AppDatabase _db;
  final CookieVault _vault;

  @override
  Future<List<DetectedRole>> detectRoles({
    required String accountId,
    required String hoyolabUid,
  }) async {
    final response = await guardHoyolab(
      () => _dio.getUri<Map<String, dynamic>>(
        Uri.https(HoyolabConfig.gameRecordHost, HoyolabConfig.recordCardPath, {
          'uid': hoyolabUid,
        }),
        options: hoyolabOptions(
          accountId: accountId,
          profile: HeaderProfile.gameRecord,
        ),
      ),
    );
    return _parseRoles(response.data);
  }

  @override
  Future<void> saveAccount({
    required String accountId,
    required HoyolabCookie cookie,
    required List<DetectedRole> roles,
    required Set<DetectedRole> selected,
  }) async {
    if (roles.isEmpty) throw const NoRolesException();
    await _vault.save(accountId, cookie);
    final nickname =
        (roles.where(selected.contains).firstOrNull ?? roles.first).nickname;
    await _guardDb(
      () => _db.transaction(() async {
        await _upsertAccount(accountId, nickname);
        for (final role in roles) {
          await _upsertRole(accountId, role, enabled: selected.contains(role));
        }
      }),
    );
  }

  @override
  Stream<List<AccountSummary>> watchAccounts() {
    final query =
        _db.select(_db.accounts).join([
          leftOuterJoin(
            _db.gameRoles,
            _db.gameRoles.accountId.equalsExp(_db.accounts.id),
          ),
        ])..orderBy([
          OrderingTerm.asc(_db.accounts.createdAt),
          OrderingTerm.asc(_db.gameRoles.id),
        ]);
    return query.watch().map(_groupAccounts);
  }

  List<AccountSummary> _groupAccounts(List<TypedResult> rows) {
    final accounts = <String, Account>{};
    final roles = <String, List<SavedRole>>{};
    for (final row in rows) {
      final account = row.readTable(_db.accounts);
      accounts[account.id] = account;
      final role = row.readTableOrNull(_db.gameRoles);
      final list = roles.putIfAbsent(account.id, () => []);
      if (role != null) list.add(_toSavedRole(role));
    }
    return [
      for (final account in accounts.values)
        AccountSummary(
          id: account.id,
          nickname: account.nickname,
          status: account.status,
          updatedAt: account.updatedAt,
          roles: List.unmodifiable(roles[account.id] ?? const <SavedRole>[]),
        ),
    ];
  }

  static SavedRole _toSavedRole(GameRole role) => SavedRole(
    id: role.id,
    accountId: role.accountId,
    game: role.game,
    uid: role.uid,
    server: role.server,
    nickname: role.nickname,
    level: role.level,
    enabled: role.enabled,
  );

  @override
  Future<int> countWidgets(String accountId) => _guardDb(() {
    final count = _db.widgetConfigs.widgetId.count();
    final query = _db.selectOnly(_db.widgetConfigs)
      ..addColumns([count])
      ..where(_db.widgetConfigs.accountId.equals(accountId));
    return query.map((row) => row.read(count) ?? 0).getSingle();
  });

  @override
  Future<void> deleteAccount(String accountId) async {
    await _vault.delete(accountId);
    await _guardDb(
      () => _db.transaction(() async {
        await (_db.delete(
          _db.widgetConfigs,
        )..where((w) => w.accountId.equals(accountId))).go();
        await (_db.delete(
          _db.accounts,
        )..where((a) => a.id.equals(accountId))).go();
      }),
    );
  }

  static Future<T> _guardDb<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } on Exception catch (e) {
      throw UnknownException('database: ${e.runtimeType}');
    }
  }

  Future<void> _upsertAccount(String accountId, String nickname) {
    final now = DateTime.now();
    return _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: accountId,
            nickname: nickname,
            status: AccountStatus.valid,
            createdAt: now,
            updatedAt: now,
          ),
          onConflict: DoUpdate(
            (_) => AccountsCompanion(
              nickname: Value(nickname),
              status: const Value(AccountStatus.valid),
              updatedAt: Value(now),
            ),
          ),
        );
  }

  Future<void> _upsertRole(
    String accountId,
    DetectedRole role, {
    required bool enabled,
  }) {
    final roles = _db.gameRoles;
    return _db
        .into(roles)
        .insert(
          GameRolesCompanion.insert(
            accountId: accountId,
            game: role.game,
            uid: role.uid,
            server: role.server,
            nickname: role.nickname,
            level: role.level,
            enabled: Value(enabled),
          ),
          onConflict: DoUpdate(
            (_) => GameRolesCompanion(
              server: Value(role.server),
              nickname: Value(role.nickname),
              level: Value(role.level),
              enabled: Value(enabled),
            ),
            target: [roles.accountId, roles.game, roles.uid],
          ),
        );
  }

  static List<DetectedRole> _parseRoles(Map<String, dynamic>? body) {
    final data = body?['data'];
    final list = data is Map<String, dynamic> ? data['list'] : null;
    if (list is! List) return const [];
    try {
      return [
        for (final card in list.whereType<Map<String, dynamic>>())
          ?_toRole(RecordCardDto.fromJson(card)),
      ];
    } on CheckedFromJsonException catch (e) {
      throw ParseException('record card: ${e.key}');
    }
  }

  static DetectedRole? _toRole(RecordCardDto dto) {
    final game = gameFromHoyolabId(dto.gameId);
    if (game == null || !dto.hasRole || dto.gameRoleId.isEmpty) return null;
    return DetectedRole(
      game: game,
      uid: dto.gameRoleId,
      server: dto.region,
      region: regionFromServerId(game, dto.region),
      regionName: dto.regionName,
      nickname: dto.nickname,
      level: dto.level,
    );
  }
}

@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) => AccountRepositoryImpl(
  ref.watch(hoyolabDioProvider),
  ref.watch(appDatabaseProvider),
  ref.watch(cookieVaultProvider),
);
