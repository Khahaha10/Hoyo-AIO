import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CookieCipher {
  CookieCipher(this._storage);

  static const versionPrefix = 'v1:';
  static const _keyName = 'hoyolab_cookie_key.v1';
  static const _nonceLength = 12;
  static const _macLength = 16;

  final FlutterSecureStorage _storage;
  final _algorithm = AesGcm.with256bits();
  Future<SecretKey>? _key;

  static bool isEncrypted(String stored) => stored.startsWith(versionPrefix);

  Future<String> encrypt(String plain, {required String accountId}) async {
    final box = await _algorithm.encrypt(
      utf8.encode(plain),
      secretKey: await _secretKey(),
      aad: utf8.encode(accountId),
    );
    return '$versionPrefix${base64Encode(box.concatenation())}';
  }

  Future<String?> decrypt(String stored, {required String accountId}) async {
    if (!isEncrypted(stored)) return null;
    try {
      final box = SecretBox.fromConcatenation(
        base64Decode(stored.substring(versionPrefix.length)),
        nonceLength: _nonceLength,
        macLength: _macLength,
      );
      final clear = await _algorithm.decrypt(
        box,
        secretKey: await _secretKey(),
        aad: utf8.encode(accountId),
      );
      return utf8.decode(clear);
    } on SecretBoxAuthenticationError {
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<SecretKey> _secretKey() => _key ??= _loadOrCreateKey();

  Future<SecretKey> _loadOrCreateKey() async {
    final stored = await _storage.read(key: _keyName);
    if (stored != null) return SecretKey(base64Decode(stored));
    final key = await _algorithm.newSecretKey();
    await _storage.write(
      key: _keyName,
      value: base64Encode(await key.extractBytes()),
    );
    return key;
  }
}
