import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/storage/cookie_cipher.dart';
import 'package:hoyo_aio/core/storage/hoyolab_cookie.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cookie_vault.g.dart';

class CookieVault {
  CookieVault([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(aOptions: _android, iOptions: _ios) {
    _cipher = CookieCipher(_storage);
  }

  static const _android = AndroidOptions();
  static const _ios = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );
  static const _keyPrefix = 'hoyolab_cookie.';

  final FlutterSecureStorage _storage;
  late final CookieCipher _cipher;

  Future<void> save(String accountId, HoyolabCookie cookie) async {
    if (!cookie.isUsable) throw const CookieExpiredException();
    await _guard(() async {
      final sealed = await _cipher.encrypt(
        cookie.serialize(),
        accountId: accountId,
      );
      await _storage.write(key: _key(accountId), value: sealed);
    });
  }

  Future<HoyolabCookie?> read(String accountId) => _guard(() async {
    final stored = await _storage.read(key: _key(accountId));
    if (stored == null) return null;
    if (!CookieCipher.isEncrypted(stored)) {
      final legacy = HoyolabCookie.parse(stored);
      if (!legacy.isUsable) return null;
      await save(accountId, legacy);
      return legacy;
    }
    final clear = await _cipher.decrypt(stored, accountId: accountId);
    if (clear == null) return null;
    final cookie = HoyolabCookie.parse(clear);
    return cookie.isUsable ? cookie : null;
  });

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
