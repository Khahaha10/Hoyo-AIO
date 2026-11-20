import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/game_region.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';

void main() {
  group('Game <-> HoYoLAB game_id', () {
    test('maps the documented ids both ways', () {
      const expected = {
        Game.hi3: 1,
        Game.genshin: 2,
        Game.starRail: 6,
        Game.zzz: 8,
      };
      for (final MapEntry(key: game, value: id) in expected.entries) {
        expect(game.hoyolabGameId, id);
        expect(gameFromHoyolabId(id), game);
      }
    });

    test('unknown ids return null', () {
      expect(gameFromHoyolabId(3), isNull);
      expect(gameFromHoyolabId(-1), isNull);
    });
  });

  group('Server ids', () {
    test('match the documented table', () {
      const table = {
        Game.genshin: ['os_asia', 'os_usa', 'os_euro', 'os_cht'],
        Game.starRail: [
          'prod_official_asia',
          'prod_official_usa',
          'prod_official_eur',
          'prod_official_cht',
        ],
        Game.zzz: ['prod_gf_jp', 'prod_gf_us', 'prod_gf_eu', 'prod_gf_sg'],
      };
      const regions = [
        GameRegion.asia,
        GameRegion.america,
        GameRegion.europe,
        GameRegion.twHkMo,
      ];
      for (final MapEntry(key: game, value: ids) in table.entries) {
        for (var i = 0; i < regions.length; i++) {
          expect(regions[i].serverIdFor(game), ids[i]);
          expect(regionFromServerId(game, ids[i]), regions[i]);
        }
      }
    });

    test('HI3 has no server ids', () {
      expect(GameRegion.asia.serverIdFor(Game.hi3), isNull);
      expect(regionFromServerId(Game.hi3, 'os_asia'), isNull);
    });

    test('a server id of another game is rejected', () {
      expect(regionFromServerId(Game.genshin, 'prod_gf_jp'), isNull);
      expect(regionFromServerId(Game.zzz, 'os_asia'), isNull);
    });
  });

  group('Check-in endpoints', () {
    test('every game has a check-in endpoint on an allowed host', () {
      for (final game in Game.values) {
        final endpoint = HoyolabConfig.checkIn[game];
        expect(endpoint, isNotNull, reason: '$game');
        expect(HoyolabConfig.allowedHosts, contains(endpoint!.host));
        expect(endpoint.actId, startsWith('e20'));
      }
    });

    test('act ids match the reference values', () {
      expect(HoyolabConfig.checkIn[Game.genshin]!.actId, 'e202102251931481');
      expect(HoyolabConfig.checkIn[Game.starRail]!.actId, 'e202303301540311');
      expect(HoyolabConfig.checkIn[Game.hi3]!.actId, 'e202110291205111');
      expect(HoyolabConfig.checkIn[Game.zzz]!.actId, 'e202406031448091');
    });

    test('only ZZZ sends the claim parameters as a JSON body', () {
      for (final game in Game.values) {
        expect(
          HoyolabConfig.checkIn[game]!.paramsInBody,
          game == Game.zzz,
          reason: '$game',
        );
      }
    });
  });

  group('Allowlist', () {
    test('contains exactly the API hosts, all https-only names', () {
      expect(HoyolabConfig.allowedHosts, {
        'bbs-api-os.hoyoverse.com',
        'sg-act-nap-api.hoyolab.com',
        'sg-hk4e-api.hoyolab.com',
        'sg-public-api.hoyolab.com',
      });
    });

    test('WebView hosts are separate from the API allowlist', () {
      expect(
        HoyolabConfig.webViewHosts.intersection(HoyolabConfig.allowedHosts),
        isEmpty,
      );
    });
  });
}
