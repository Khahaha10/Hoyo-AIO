import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_link.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_record.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_repository.dart';
import 'package:material_ui/material_ui.dart';

typedef RequestHandler = FutureOr<Object?> Function(RequestOptions options);

Dio fakeDio(RequestHandler handle) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final body = await handle(options);
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: jsonDecode(jsonEncode(body)),
            ),
          );
        } on AppException catch (error) {
          handler.reject(DioException(requestOptions: options, error: error));
        }
      },
    ),
  );
  return dio;
}

final testNow = DateTime(2026, 11, 21, 12);

const fakeAuthkey = 'FAKE-AUTHKEY-123456';

String genshinLink({String authkey = fakeAuthkey}) =>
    'https://public-operation-hk4e-sg.hoyoverse.com/gacha_info/api/'
    'getGachaLog?authkey_ver=1&sign_type=2&auth_appid=webview_gacha'
    '&authkey=$authkey&lang=en&game_biz=hk4e_global&region=os_asia'
    '&init_type=301&timestamp=1';

GachaRecord gachaRecord(
  int id, {
  int rank = 3,
  String name = 'Item',
  String banner = '301',
  Game game = Game.genshin,
  String time = '2026-11-20 10:00:00',
  String itemType = 'Weapon',
}) => GachaRecord(
  game: game,
  id: id,
  uid: '800000001',
  banner: banner,
  name: name,
  itemType: itemType,
  rank: rank,
  time: time,
);

class FakeGachaRepository implements GachaRepository {
  FakeGachaRepository({Map<Game, List<GachaRecord>>? records, this.expiry})
    : records = records ?? {};

  final Map<Game, List<GachaRecord>> records;
  final _changes = StreamController<void>.broadcast();
  DateTime? expiry;
  Object? syncError;
  Completer<void>? syncGate;
  final syncCalls = <Game>[];
  final imported = <String>[];

  @override
  Future<Game> importLink(String raw) async {
    final link = GachaLink.parse(raw, testNow);
    if (link == null) throw const ParseException('gacha link');
    imported.add(raw);
    return link.game;
  }

  @override
  Future<DateTime?> linkExpiresAt(Game game) async => expiry;

  @override
  Future<int> sync(Game game, {void Function(int fetched)? onProgress}) async {
    syncCalls.add(game);
    onProgress?.call(7);
    await syncGate?.future;
    if (syncError case final error?) throw error;
    return 7;
  }

  @override
  Stream<List<GachaRecord>> watch(Game game) async* {
    yield records[game] ?? const [];
    await for (final _ in _changes.stream) {
      yield records[game] ?? const [];
    }
  }

  void emit() => _changes.add(null);
}

List<Override> clockOverrides([DateTime? now]) => [
  clockProvider.overrideWithValue(() => now ?? testNow),
  clockTickProvider.overrideWith((ref) => Stream.value(now ?? testNow)),
];

Future<void> pumpScreen(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  bool dark = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void useTallSurface(WidgetTester tester, {double width = 390}) {
  tester.view.physicalSize = Size(width * 3, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

class PlatformRecorder {
  final clipboard = <String>[];
  String? clipboardText;
  final launched = <String>[];
  final shared = <Map<Object?, Object?>>[];

  void install(WidgetTester tester) {
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        final text = (call.arguments as Map<Object?, Object?>)['text'];
        clipboard.add('$text');
        return null;
      }
      if (call.method == 'Clipboard.getData') {
        return clipboardText == null ? null : {'text': clipboardText};
      }
      return null;
    });
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (call) async {
        if (call.method == 'canLaunch') return true;
        launched.add('${(call.arguments as Map<Object?, Object?>)['url']}');
        return true;
      },
    );
    addTearDown(() {
      messenger
        ..setMockMethodCallHandler(SystemChannels.platform, null)
        ..setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          null,
        );
    });
  }
}
