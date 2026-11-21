import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/storage/hoyolab_cookie.dart';

bool isAllowedWebViewUri(Uri uri) {
  if (uri.scheme == 'about') return true;
  if (uri.scheme != 'https') return false;
  return HoyolabConfig.webViewHostSuffixes.any(
    (suffix) => uri.host == suffix || uri.host.endsWith('.$suffix'),
  );
}

class WebViewCookieReader {
  WebViewCookieReader({CookieManager? cookieManager})
    : _cookies = cookieManager ?? CookieManager.instance();

  final CookieManager _cookies;

  Future<HoyolabCookie> read() async {
    final pairs = <String, String>{};
    for (final url in HoyolabConfig.webViewCookieUrls) {
      final cookies = await _cookies.getCookies(url: WebUri(url));
      for (final cookie in cookies) {
        final value = cookie.value;
        if (value is String && value.isNotEmpty) pairs[cookie.name] = value;
      }
    }
    return HoyolabCookie.parse(
      pairs.entries.map((e) => '${e.key}=${e.value}').join('; '),
    );
  }

  Future<void> clear() async {
    await _cookies.deleteAllCookies();
    await InAppWebViewController.clearAllCache();
    await WebStorageManager.instance().deleteAllData();
  }
}
