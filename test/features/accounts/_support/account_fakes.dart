import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/provider_retry.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/game_region.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/storage/cookie_vault.dart';
import 'package:hoyo_aio/core/storage/hoyolab_cookie.dart';
import 'package:hoyo_aio/features/accounts/domain/account_repository.dart';
import 'package:hoyo_aio/features/accounts/domain/account_summary.dart';
import 'package:hoyo_aio/features/accounts/domain/detected_role.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:material_ui/material_ui.dart';

const fakeUid = '800000001';
const fakeCookieText = 'ltuid_v2=$fakeUid; ltoken_v2=fake';

final enL10n = lookupAppLocalizations(const Locale('en'));

class FakeCookieVault extends CookieVault {
  final stored = <String, HoyolabCookie>{};
  final log = <String>[];

  @override
  Future<void> save(String accountId, HoyolabCookie cookie) async {
    if (!cookie.isUsable) throw const CookieExpiredException();
    log.add('save:$accountId');
    stored[accountId] = cookie;
  }

  @override
  Future<HoyolabCookie?> read(String accountId) async => stored[accountId];

  @override
  Future<void> delete(String accountId) async {
    log.add('delete:$accountId');
    stored.remove(accountId);
  }
}

class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.body);

  Object? body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository({
    this.roles = const [],
    this.accounts = const [],
    this.widgets = 0,
  });

  List<DetectedRole> roles;
  List<AccountSummary> accounts;
  int widgets;
  AppException? detectError;
  AppException? saveError;
  AppException? deleteError;
  final detectCalls = <String>[];
  final saved =
      <({String accountId, String cookie, Set<DetectedRole> selected})>[];
  final deleted = <String>[];

  @override
  Future<List<DetectedRole>> detectRoles({
    required String accountId,
    required String hoyolabUid,
  }) async {
    detectCalls.add(accountId);
    if (detectError case final error?) throw error;
    return roles;
  }

  @override
  Future<void> saveAccount({
    required String accountId,
    required HoyolabCookie cookie,
    required List<DetectedRole> roles,
    required Set<DetectedRole> selected,
  }) async {
    if (saveError case final error?) throw error;
    saved.add((
      accountId: accountId,
      cookie: cookie.serialize(),
      selected: selected,
    ));
  }

  @override
  Stream<List<AccountSummary>> watchAccounts() => Stream.value(accounts);

  @override
  Future<int> countWidgets(String accountId) async => widgets;

  @override
  Future<void> deleteAccount(String accountId) async {
    if (deleteError case final error?) throw error;
    deleted.add(accountId);
  }
}

DetectedRole detectedRole(Game game, {String uid = fakeUid}) => DetectedRole(
  game: game,
  uid: uid,
  server: 'os_asia',
  region: GameRegion.asia,
  regionName: 'Asia',
  nickname: 'Tester ${game.name}',
  level: 60,
);

SavedRole savedRole(
  int id,
  Game game, {
  String accountId = fakeUid,
  bool enabled = true,
}) => SavedRole(
  id: id,
  accountId: accountId,
  game: game,
  uid: '80000000$id',
  server: 'os_asia',
  nickname: 'Role $id',
  level: 60,
  enabled: enabled,
);

AccountSummary accountSummary({
  String id = fakeUid,
  String nickname = 'Traveler',
  AccountStatus status = AccountStatus.valid,
  List<SavedRole> roles = const [],
}) => AccountSummary(
  id: id,
  nickname: nickname,
  status: status,
  updatedAt: DateTime.utc(2026, 1, 2, 3, 4),
  roles: roles,
);

class RouteLog {
  final pushed = <String>[];

  void add(String uri) {
    if (!pushed.contains(uri)) pushed.add(uri);
  }
}

Future<RouteLog> pumpRouted(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
  ProviderContainer? container,
  String? initialLocation,
  Size? size,
}) async {
  if (size != null) tester.view.physicalSize = size;
  final log = RouteLog();
  final router = GoRouter(
    initialLocation: initialLocation ?? '/start',
    routes: [
      GoRoute(path: '/start', builder: (_, _) => screen),
      GoRoute(
        path: '/home',
        builder: (_, _) => const SizedBox(),
        routes: [GoRoute(path: 'screen', builder: (_, _) => screen)],
      ),
      GoRoute(
        path: '/:a',
        builder: (_, state) {
          log.add(state.uri.toString());
          return Text('route:${state.uri}');
        },
        routes: [
          GoRoute(
            path: ':b',
            builder: (_, state) {
              log.add(state.uri.toString());
              return Text('route:${state.uri}');
            },
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  final app = MaterialApp.router(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    routerConfig: router,
  );
  await tester.pumpWidget(
    container == null
        ? ProviderScope(
            retry: noProviderRetry,
            overrides: overrides,
            child: app,
          )
        : UncontrolledProviderScope(container: container, child: app),
  );
  addTearDown(tester.pump);
  if (size != null) addTearDown(tester.view.reset);
  await tester.pump();
  return log;
}
