import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/features/accounts/data/webview_cookie_reader.dart';
import 'package:mocktail/mocktail.dart';

class _MockCookieManager extends Mock implements CookieManager {}

void main() {
  setUpAll(() => registerFallbackValue(WebUri('https://www.hoyolab.com/')));

  group('isAllowedWebViewUri', () {
    test('allows HTTPS pages on hoyolab.com and hoyoverse.com hosts', () {
      for (final url in [
        'https://m.hoyolab.com/#/timeline',
        'https://hoyolab.com/',
        'https://account.hoyoverse.com/login',
        'about:blank',
      ]) {
        expect(isAllowedWebViewUri(Uri.parse(url)), isTrue, reason: url);
      }
    });

    test('blocks other hosts, look-alike hosts and plain HTTP', () {
      for (final url in [
        'http://m.hoyolab.com/',
        'https://evilhoyolab.com/',
        'https://hoyolab.com.evil.example/',
        'https://accounts.google.com/',
        'javascript:alert(1)',
      ]) {
        expect(isAllowedWebViewUri(Uri.parse(url)), isFalse, reason: url);
      }
    });
  });

  group('WebViewCookieReader.read', () {
    late _MockCookieManager manager;

    setUp(() => manager = _MockCookieManager());

    test('keeps only needed cookie keys from the HoYoLAB urls', () async {
      when(() => manager.getCookies(url: any(named: 'url'))).thenAnswer(
        (invocation) async {
          final url = invocation.namedArguments[#url] as WebUri;
          return url.host == 'www.hoyolab.com'
              ? [
                  Cookie(name: 'ltuid_v2', value: '800000001'),
                  Cookie(name: 'ltoken_v2', value: 'fake'),
                  Cookie(name: '_ga', value: 'tracker'),
                  Cookie(name: 'mi18nLang', value: 'en-us'),
                ]
              : [
                  Cookie(name: 'ltmid_v2', value: 'mid'),
                  Cookie(name: 'cookie_token_v2', value: ''),
                  Cookie(name: 'account_id_v2', value: 42),
                ];
        },
      );

      final cookie = await WebViewCookieReader(cookieManager: manager).read();

      expect(cookie.values, {
        'ltuid_v2': '800000001',
        'ltoken_v2': 'fake',
        'ltmid_v2': 'mid',
      });
      expect(cookie.isUsable, isTrue);
      final asked = verify(
        () => manager.getCookies(url: captureAny(named: 'url')),
      ).captured.cast<WebUri>().map((u) => u.toString()).toList();
      expect(asked, HoyolabConfig.webViewCookieUrls);
    });

    test('returns an unusable cookie when the user is not logged in', () async {
      when(
        () => manager.getCookies(url: any(named: 'url')),
      ).thenAnswer((_) async => [Cookie(name: '_ga', value: 'x')]);

      final cookie = await WebViewCookieReader(cookieManager: manager).read();

      expect(cookie.values, isEmpty);
      expect(cookie.isUsable, isFalse);
    });
  });
}
