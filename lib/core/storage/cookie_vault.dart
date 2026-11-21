import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/storage/hoyolab_cookie.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cookie_vault.g.dart';

class CookieVault {
  CookieVault([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(aOptions: _android, iOptions: _ios);

  static const _android = AndroidOptions();
  static const _ios = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );
  static const _keyPrefix = 'hoyolab_cookie.';

  final FlutterSecureStorage _storage;

  Future<void> save(String accountId, HoyolabCookie cookie) async {
    if (!cookie.isUsable) throw const CookieExpiredException();
    await _guard(
      () => _storage.write(key: _key(accountId), value: cookie.serialize()),
    );
  }

  Future<HoyolabCookie?> read(String accountId) async {
    final raw = await _guard(() => _storage.read(key: _key(accountId)));
    if (raw == null) return null;
    final cookie = HoyolabCookie.parse(raw);
    return cookie.isUsable ? cookie : null;
  }

  Future<String?> cookieHeader(String accountId) async =>
      (await read(accountId))?.serialize();

  Future<void> delete(String accountId) =>
      _guard(() => _storage.delete(key: _key(accountId)));

  String _key(String accountId) => '$_keyPrefix$accountId';

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PlatformException catch (e) {
      throw UnknownException('secure storage: ${e.code}');
    }
  }
}

@Riverpod(keepAlive: true)
CookieVault cookieVault(Ref ref) => CookieVault();
