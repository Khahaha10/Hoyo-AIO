import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_link.dart';

import '../_support/tracker_support.dart';

void main() {
  group('GachaLink.parse accepts official links', () {
    test('keeps only the needed params from an API link', () {
      final link = GachaLink.parse(genshinLink(), testNow);

      expect(link?.game, Game.genshin);
      expect(link?.params, {
        'authkey': fakeAuthkey,
        'authkey_ver': '1',
        'sign_type': '2',
        'auth_appid': 'webview_gacha',
        'region': 'os_asia',
        'game_biz': 'hk4e_global',
      });
    });

    test('finds the link inside surrounding text', () {
      final link = GachaLink.parse('copied: ${genshinLink()} done', testNow);

      expect(link?.params['authkey'], fakeAuthkey);
    });

    test(
      'reads params from the page fragment and detects the game by path',
      () {
        final link = GachaLink.parse(
          'https://gs.hoyoverse.com/genshin/event/e20190909gacha-v3/index.html'
          '?win_mode=fullscreen#/log?authkey=FRAGKEY&region=os_euro',
          testNow,
        );

        expect(link?.game, Game.genshin);
        expect(link?.params, {'authkey': 'FRAGKEY', 'region': 'os_euro'});
      },
    );

    for (final (biz, game) in [
      ('hkrpg_global', Game.starRail),
      ('nap_global', Game.zzz),
    ]) {
      test('maps game_biz $biz to $game', () {
        final link = GachaLink.parse(
          'https://public-operation-x-sg.hoyoverse.com/common/gacha_record/'
          'api/getGachaLog?authkey=K&game_biz=$biz',
          testNow,
        );

        expect(link?.game, game);
      });
    }

    for (final (marker, game) in [
      ('hkrpg', Game.starRail),
      ('nap', Game.zzz),
      ('hk4e', Game.genshin),
    ]) {
      test('detects $game from the /$marker/ path marker', () {
        final link = GachaLink.parse(
          'https://webstatic.hoyoverse.com/$marker/event/index.html?authkey=K',
          testNow,
        );

        expect(link?.game, game);
      });
    }

    test('expires 24 hours after import', () {
      final link = GachaLink.parse(genshinLink(), testNow);

      expect(link?.expiresAt, testNow.add(HoyolabConfig.gachaAuthkeyLifetime));
      expect(link?.isValidAt(testNow.add(const Duration(hours: 23))), isTrue);
      expect(link?.isValidAt(testNow.add(const Duration(hours: 24))), isFalse);
    });
  });

  group('GachaLink.parse rejects', () {
    final cases = {
      'plain http': genshinLink().replaceFirst('https', 'http'),
      'other hosts':
          'https://evil.example.com/x?authkey=K&game_biz=hk4e_global',
      'missing authkey': genshinLink().replaceFirst(
        'authkey=$fakeAuthkey&',
        '',
      ),
      'empty authkey': genshinLink(authkey: ''),
      'unknown game':
          'https://webstatic.hoyoverse.com/other/index.html?authkey=K',
      'non-link text': 'hello there',
      'empty text': '   ',
    };
    for (final MapEntry(key: name, value: raw) in cases.entries) {
      test(name, () {
        expect(GachaLink.parse(raw, testNow), isNull);
      });
    }
  });
}
