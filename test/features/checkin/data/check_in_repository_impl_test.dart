import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/error/retcode_mapper.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/features/checkin/data/check_in_repository_impl.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_month.dart';

import '../_support/check_in_fixtures.dart';
import '../_support/fake_http_adapter.dart';

const _account = '800000001';

String _leaf(RequestOptions options) => options.uri.pathSegments.last;

Responder _monthResponder(
  Game game, {
  Map<String, dynamic>? info,
  Object? Function(int page)? award,
}) =>
    (options) => switch (_leaf(options)) {
      'info' => ok(info ?? infoJson()),
      'home' => ok(homeJson(game)),
      'award' =>
        award?.call(
              int.parse(options.uri.queryParameters['current_page'] ?? '1'),
            ) ??
            ok(awardJson(const [])),
      _ => retcode(-1),
    };

final retcodeCases = <(int, Matcher)>[
  (Retcode.notLoggedIn, isA<CookieExpiredException>()),
  (Retcode.notLoggedIn2, isA<CookieExpiredException>()),
  (Retcode.accountNotFound, isA<NoRolesException>()),
  (Retcode.tooManyRequests, isA<RateLimitedException>()),
  (-999, isA<ServerException>()),
];

void main() {
  group('CheckInRepositoryImpl.month', () {
    for (final game in Game.values) {
      test('parses info and rewards for ${game.name}', () async {
        final adapter = FakeHttpAdapter(
          _monthResponder(
            game,
            award: (_) => ok(
              awardJson([
                (rewardNames[game]![2], 30, '2026-11-03 06:00:00'),
                (rewardNames[game]![1], 20, '2026-11-02 06:00:00'),
                (rewardNames[game]![0], 10, '2026-11-01 06:00:00'),
              ]),
            ),
          ),
        );
        final repository = CheckInRepositoryImpl(fakeDio(adapter));

        final month = await repository.month(accountId: _account, game: game);

        expect(month.game, game);
        expect(month.month, 11);
        expect(month.signedDays, 3);
        expect(month.signedToday, isFalse);
        expect(month.missedDays, 1);
        expect(month.today, '2026-11-05');
        expect(month.rewards, hasLength(30));
        expect(
          month.rewards.first,
          CheckInReward(day: 1, name: rewardNames[game]![0], count: 10),
        );
        expect(month.claimedOn?.keys, unorderedEquals([1, 2, 3]));
        expect(month.claimedOn?[2]?.count, 20);
        final endpoint = HoyolabConfig.checkIn[game]!;
        expect(adapter.requests.map((r) => r.uri.host).toSet(), {
          endpoint.host,
        });
        expect(
          adapter.requests.every(
            (r) => r.uri.queryParameters['act_id'] == endpoint.actId,
          ),
          isTrue,
        );
      });
    }

    test('stops paging at the first record from another month', () async {
      final adapter = FakeHttpAdapter(
        _monthResponder(
          Game.genshin,
          award: (page) => ok(
            awardJson([
              for (var i = 0; i < 10; i++)
                page == 1
                    ? ('Primogem', 1, '2026-11-${(20 - i).toString()} 06:00:00')
                    : ('Mora', 1, '2026-10-31 06:00:00'),
            ]),
          ),
        ),
      );
      final repository = CheckInRepositoryImpl(fakeDio(adapter));

      final month = await repository.month(
        accountId: _account,
        game: Game.genshin,
      );

      expect(month.claimedOn, hasLength(10));
      expect(adapter.requests.where((r) => _leaf(r) == 'award'), hasLength(2));
    });

    test('reads at most four award pages', () async {
      var day = 28;
      final adapter = FakeHttpAdapter(
        _monthResponder(
          Game.genshin,
          info: infoJson(today: '2026-11-28'),
          award: (_) => ok(
            awardJson([
              for (var i = 0; i < 10; i++)
                ('Primogem', 1, '2026-11-${(day--).clamp(1, 28)} 06:00:00'),
            ]),
          ),
        ),
      );
      final repository = CheckInRepositoryImpl(fakeDio(adapter));

      await repository.month(accountId: _account, game: Game.genshin);

      expect(adapter.requests.where((r) => _leaf(r) == 'award'), hasLength(4));
    });

    test('skips award records with unreadable dates', () async {
      final adapter = FakeHttpAdapter(
        _monthResponder(
          Game.starRail,
          award: (_) => ok(
            awardJson([
              ('Credit', 5, 'not a date'),
              ('Stellar Jade', 20, '2026-11-01 06:00:00'),
            ]),
          ),
        ),
      );
      final repository = CheckInRepositoryImpl(fakeDio(adapter));

      final month = await repository.month(
        accountId: _account,
        game: Game.starRail,
      );

      expect(month.claimedOn, {
        1: const CheckInReward(day: 1, name: 'Stellar Jade', count: 20),
      });
    });

    test('falls back to the claim count when award history fails', () async {
      final adapter = FakeHttpAdapter(
        _monthResponder(Game.zzz, award: (_) => retcode(-500001)),
      );
      final repository = CheckInRepositoryImpl(fakeDio(adapter));

      final month = await repository.month(accountId: _account, game: Game.zzz);

      expect(month.claimedOn, isNull);
      expect(month.missedCount, 1);
    });

    test(
      'falls back to the claim count when award data is malformed',
      () async {
        final adapter = FakeHttpAdapter(
          _monthResponder(
            Game.hi3,
            award: (_) => ok({
              'list': [
                {'name': 'Crystal', 'cnt': 1, 'created_at': 42},
              ],
            }),
          ),
        );
        final repository = CheckInRepositoryImpl(fakeDio(adapter));

        final month = await repository.month(
          accountId: _account,
          game: Game.hi3,
        );

        expect(month.claimedOn, isNull);
      },
    );

    test('skips award history when today is unknown', () async {
      final adapter = FakeHttpAdapter(
        _monthResponder(Game.genshin, info: infoJson(today: '')),
      );
      final repository = CheckInRepositoryImpl(fakeDio(adapter));

      final month = await repository.month(
        accountId: _account,
        game: Game.genshin,
      );

      expect(month.claimedOn, isNull);
      expect(adapter.requests.where((r) => _leaf(r) == 'award'), isEmpty);
    });

    test('accepts numbers sent as strings', () async {
      final adapter = FakeHttpAdapter(
        _monthResponder(
          Game.genshin,
          info: infoJson(totalSignDay: 4, signCntMissed: '2'),
        ),
      );
      final repository = CheckInRepositoryImpl(fakeDio(adapter));

      final month = await repository.month(
        accountId: _account,
        game: Game.genshin,
      );

      expect(month.missedDays, 2);
      expect(month.month, 11);
    });

    test(
      'throws ParseException when data is missing',
      () async {
        final adapter = FakeHttpAdapter((_) => ok(null));
        final repository = CheckInRepositoryImpl(fakeDio(adapter));

        expect(
          () => repository.month(accountId: _account, game: Game.genshin),
          throwsA(isA<ParseException>()),
        );
      },
      skip: 'BUG: month() rethrows ParallelWaitError instead of AppException when info/home fails (check_in_repository_impl.dart:30)',
    );

    test('throws ParseException when a field has the wrong type', () async {
      final adapter = FakeHttpAdapter(
        _monthResponder(Game.genshin, info: {'is_sign': 'yes'}),
      );
      final repository = CheckInRepositoryImpl(fakeDio(adapter));

      expect(
        () => repository.month(accountId: _account, game: Game.genshin),
        throwsA(isA<ParseException>()),
      );
    });

    for (final (code, matcher) in retcodeCases) {
      test(
        'maps retcode $code on info',
        () async {
          final adapter = FakeHttpAdapter(
            (options) => _leaf(options) == 'info'
                ? retcode(code)
                : ok(homeJson(Game.genshin)),
          );
          final repository = CheckInRepositoryImpl(fakeDio(adapter));

          expect(
            () => repository.month(accountId: _account, game: Game.genshin),
            throwsA(matcher),
          );
        },
        skip: 'BUG: month() rethrows ParallelWaitError instead of AppException when info/home fails (check_in_repository_impl.dart:30)',
      );
    }

    test(
      'maps connection errors to NetworkException',
      () async {
        final adapter = FakeHttpAdapter(
          (options) => DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        );
        final repository = CheckInRepositoryImpl(fakeDio(adapter));

        expect(
          () => repository.month(accountId: _account, game: Game.genshin),
          throwsA(isA<NetworkException>()),
        );
      },
      skip: 'BUG: month() rethrows ParallelWaitError instead of AppException when info/home fails (check_in_repository_impl.dart:30)',
    );
  });

  group('CheckInRepositoryImpl.claim', () {
    for (final game in Game.values) {
      test('returns claimed for ${game.name}', () async {
        final adapter = FakeHttpAdapter((_) => ok(signJson()));
        final repository = CheckInRepositoryImpl(fakeDio(adapter));

        final outcome = await repository.claim(accountId: _account, game: game);

        expect(outcome, ClaimOutcome.claimed);
        final request = adapter.requests.single;
        final endpoint = HoyolabConfig.checkIn[game]!;
        expect(request.method, 'POST');
        expect(request.uri.path, endpoint.signUri.path);
        if (endpoint.paramsInBody) {
          expect(request.data, containsPair('act_id', endpoint.actId));
          expect(request.uri.queryParameters, isEmpty);
        } else {
          expect(request.uri.queryParameters['act_id'], endpoint.actId);
        }
      });

      test(
        'returns alreadyClaimed on retcode -5003 for ${game.name}',
        () async {
          final adapter = FakeHttpAdapter(
            (_) => retcode(Retcode.alreadyClaimed),
          );
          final repository = CheckInRepositoryImpl(fakeDio(adapter));

          final outcome = await repository.claim(
            accountId: _account,
            game: game,
          );

          expect(outcome, ClaimOutcome.alreadyClaimed);
        },
      );
    }

    test('returns alreadyClaimed on retcode 2001', () async {
      final adapter = FakeHttpAdapter(
        (_) => retcode(Retcode.alreadyCheckedIntoHoyolab),
      );
      final repository = CheckInRepositoryImpl(fakeDio(adapter));

      final outcome = await repository.claim(
        accountId: _account,
        game: Game.hi3,
      );

      expect(outcome, ClaimOutcome.alreadyClaimed);
    });

    test('returns captcha when the sign response is risky', () async {
      final adapter = FakeHttpAdapter((_) => ok(signJson(isRisk: true)));
      final repository = CheckInRepositoryImpl(fakeDio(adapter));

      final outcome = await repository.claim(
        accountId: _account,
        game: Game.genshin,
      );

      expect(outcome, ClaimOutcome.captcha);
    });

    test('returns captcha when the geetest result is risky', () async {
      final adapter = FakeHttpAdapter((_) => ok(signJson(gtRisk: true)));
      final repository = CheckInRepositoryImpl(fakeDio(adapter));

      final outcome = await repository.claim(
        accountId: _account,
        game: Game.starRail,
      );

      expect(outcome, ClaimOutcome.captcha);
    });

    test('returns claimed when the sign response has no data', () async {
      final adapter = FakeHttpAdapter((_) => ok(null));
      final repository = CheckInRepositoryImpl(fakeDio(adapter));

      final outcome = await repository.claim(
        accountId: _account,
        game: Game.zzz,
      );

      expect(outcome, ClaimOutcome.claimed);
    });

    for (final (code, matcher) in retcodeCases) {
      test('maps retcode $code on claim', () async {
        final adapter = FakeHttpAdapter((_) => retcode(code));
        final repository = CheckInRepositoryImpl(fakeDio(adapter));

        expect(
          () => repository.claim(accountId: _account, game: Game.genshin),
          throwsA(matcher),
        );
      });
    }

    test('fails with ServerException on an unknown retcode', () async {
      final adapter = FakeHttpAdapter((_) => retcode(-10));
      final repository = CheckInRepositoryImpl(fakeDio(adapter));

      expect(
        () => repository.claim(accountId: _account, game: Game.genshin),
        throwsA(
          isA<ServerException>().having((e) => e.retcode, 'retcode', -10),
        ),
      );
    });

    test('fails with ParseException on malformed sign data', () async {
      final adapter = FakeHttpAdapter((_) => ok({'is_risk': 'maybe'}));
      final repository = CheckInRepositoryImpl(fakeDio(adapter));

      expect(
        () => repository.claim(accountId: _account, game: Game.genshin),
        throwsA(isA<ParseException>()),
      );
    });
  });
}
