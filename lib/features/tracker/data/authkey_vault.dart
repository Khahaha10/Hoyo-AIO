import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/storage/cookie_cipher.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_link.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'authkey_vault.g.dart';

class AuthkeyVault {
  AuthkeyVault([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(aOptions: _android, iOptions: _ios) {
    _cipher = CookieCipher(_storage);
  }

  static const _android = AndroidOptions();
  static const _ios = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );
  static const _keyPrefix = 'gacha_authkey.';

  final FlutterSecureStorage _storage;
  late final CookieCipher _cipher;

  Future<void> save(GachaLink link) => _guard(() async {
    final sealed = await _cipher.encrypt(
      jsonEncode({
        'params': link.params,
        'expires_at': link.expiresAt.toUtc().toIso8601String(),
      }),
      accountId: _key(link.game),
    );
    await _storage.write(key: _key(link.game), value: sealed);
  });

  Future<GachaLink?> read(Game game, DateTime now) => _guard(() async {
    final stored = await _storage.read(key: _key(game));
    if (stored == null) return null;
    final clear = await _cipher.decrypt(stored, accountId: _key(game));
    final decoded = clear == null ? null : jsonDecode(clear);
    if (decoded case {
      'params': final Map<String, dynamic> params,
      'expires_at': final String expires,
    }) {
      final link = GachaLink(
        game: game,
        params: params.map((key, value) => MapEntry(key, '$value')),
        expiresAt: DateTime.parse(expires),
      );
      if (link.isValidAt(now)) return link;
    }
    await _storage.delete(key: _key(game));
    return null;
  });

  Future<void> delete(Game game) =>
      _guard(() => _storage.delete(key: _key(game)));

  static String _key(Game game) => '$_keyPrefix${game.name}';

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PlatformException catch (e) {
      throw UnknownException('secure storage: ${e.code}');
    } on FormatException {
      throw const ParseException('authkey vault');
    }
  }
}

@Riverpod(keepAlive: true)
AuthkeyVault authkeyVault(Ref ref) => AuthkeyVault();
