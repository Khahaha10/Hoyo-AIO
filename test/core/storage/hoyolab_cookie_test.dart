import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/storage/hoyolab_cookie.dart';

void main() {
  group('HoyolabCookie.parse', () {
    test('reads a v1 cookie', () {
      final cookie = HoyolabCookie.parse(
        'ltuid=800000001; ltoken=fake; cookie_token=fake2; account_id=800000001',
      );

      expect(cookie.hoyolabUid, '800000001');
      expect(cookie.hasLoginToken, isTrue);
      expect(cookie.isUsable, isTrue);
      expect(cookie.keyCount, 4);
    });

    test('reads a v2 cookie', () {
      final cookie = HoyolabCookie.parse(
        'ltuid_v2=800000001; ltoken_v2=v2_fake; ltmid_v2=mid_fake; '
        'account_id_v2=800000001; account_mid_v2=mid_fake; '
        'cookie_token_v2=v2_ct',
      );

      expect(cookie.hoyolabUid, '800000001');
      expect(cookie.isUsable, isTrue);
      expect(cookie.keyCount, 6);
    });

    test('reads a mixed cookie and drops unknown keys', () {
      final cookie = HoyolabCookie.parse(
        '_ga=GA1.2.3; ltuid=800000001; ltoken_v2=fake; mi18nLang=en-us',
      );

      expect(cookie.values.keys, unorderedEquals(['ltuid', 'ltoken_v2']));
      expect(cookie.isUsable, isTrue);
    });

    test('tolerates whitespace, quotes, empty parts and a trailing ;', () {
      final cookie = HoyolabCookie.parse(
        '  ltuid_v2 =  800000001 ;;  ltoken_v2="fake" ; =x; novalue; '
        'cookie_token=; ',
      );

      expect(cookie.values, {'ltuid_v2': '800000001', 'ltoken_v2': 'fake'});
    });

    test('keeps "=" inside a value', () {
      final cookie = HoyolabCookie.parse('ltuid=1; ltoken=ab==');

      expect(cookie.values['ltoken'], 'ab==');
    });

    test('falls back to account_id_v2 when ltuid is not numeric', () {
      final cookie = HoyolabCookie.parse(
        'ltuid=abc; account_id_v2=800000002; ltoken=fake',
      );

      expect(cookie.hoyolabUid, '800000002');
    });

    test('is not usable without a uid or without a token', () {
      expect(HoyolabCookie.parse('ltoken_v2=fake').isUsable, isFalse);
      expect(HoyolabCookie.parse('ltuid_v2=800000001').isUsable, isFalse);
      expect(HoyolabCookie.parse('').isUsable, isFalse);
    });
  });

  group('HoyolabCookie value semantics', () {
    test('serialize round-trips and equality follows the content', () {
      final a = HoyolabCookie.parse('ltuid=1; ltoken=fake');
      final b = HoyolabCookie.parse(a.serialize());

      expect(a.serialize(), 'ltuid=1; ltoken=fake');
      expect(b, a);
      expect(b.hashCode, a.hashCode);
      expect(a == HoyolabCookie.parse('ltuid=2; ltoken=fake'), isFalse);
    });

    test('toString lists key names only, never values', () {
      final text = HoyolabCookie.parse('ltuid=1; ltoken=fake').toString();

      expect(text, contains('ltoken'));
      expect(text, isNot(contains('fake')));
    });
  });
}
