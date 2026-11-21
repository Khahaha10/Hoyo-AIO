import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/storage/cookie_cipher.dart';
import 'package:hoyo_aio/core/storage/cookie_vault.dart';
import 'package:hoyo_aio/core/storage/hoyolab_cookie.dart';
import 'package:hoyo_aio/core/storage/pending_cookies.dart';

import '_support/memory_secure_storage.dart';

const _raw = 'ltuid_v2=800000001; ltoken_v2=fake';
const _key = 'hoyolab_cookie.800000001';

void main() {
  group('CookieCipher', () {
    test('round-trips with the same account id', () async {
      final cipher = CookieCipher(MemorySecureStorage());

      final sealed = await cipher.encrypt(_raw, accountId: '800000001');

      expect(CookieCipher.isEncrypted(sealed), isTrue);
      expect(sealed, isNot(contains('fake')));
      expect(await cipher.decrypt(sealed, accountId: '800000001'), _raw);
    });

    test('fails with another account id as associated data', () async {
      final cipher = CookieCipher(MemorySecureStorage());
      final sealed = await cipher.encrypt(_raw, accountId: '800000001');

      expect(await cipher.decrypt(sealed, accountId: '800000002'), isNull);
    });

    test('returns null for plain text and for broken base64', () async {
      final cipher = CookieCipher(MemorySecureStorage());

      expect(await cipher.decrypt(_raw, accountId: '1'), isNull);
      expect(await cipher.decrypt('v1:%%%', accountId: '1'), isNull);
    });

    test('reuses the stored key across instances', () async {
      final storage = MemorySecureStorage();
      final sealed = await CookieCipher(
        storage,
      ).encrypt(_raw, accountId: '800000001');

      final other = CookieCipher(storage);

      expect(await other.decrypt(sealed, accountId: '800000001'), _raw);
    });

    test('a new key cannot open an old value', () async {
      final sealed = await CookieCipher(
        MemorySecureStorage(),
      ).encrypt(_raw, accountId: '800000001');

      final other = CookieCipher(MemorySecureStorage());

      expect(await other.decrypt(sealed, accountId: '800000001'), isNull);
    });
  });

  group('CookieVault', () {
    late MemorySecureStorage storage;
    late CookieVault vault;

    setUp(() {
      storage = MemorySecureStorage();
      vault = CookieVault(storage);
    });

    test('saves encrypted and reads back the same cookie', () async {
      await vault.save('800000001', HoyolabCookie.parse(_raw));

      expect(storage.values[_key], startsWith(CookieCipher.versionPrefix));
      expect(storage.values[_key], isNot(contains('fake')));
      expect(await vault.read('800000001'), HoyolabCookie.parse(_raw));
      expect(await vault.cookieHeader('800000001'), _raw);
    });

    test('refuses to save an unusable cookie', () async {
      await expectLater(
        vault.save('1', HoyolabCookie.parse('ltoken_v2=fake')),
        throwsA(isA<CookieExpiredException>()),
      );
      expect(storage.values, isEmpty);
    });

    test('returns null for a missing account', () async {
      expect(await vault.read('missing'), isNull);
      expect(await vault.cookieHeader('missing'), isNull);
    });

    test('a value moved to another account key does not decrypt', () async {
      await vault.save('800000001', HoyolabCookie.parse(_raw));
      storage.values['hoyolab_cookie.800000002'] = storage.values[_key]!;

      expect(await vault.read('800000002'), isNull);
    });

    test('migrates a legacy plain-text cookie to the encrypted form', () async {
      storage.values[_key] = _raw;

      final cookie = await vault.read('800000001');

      expect(cookie, HoyolabCookie.parse(_raw));
      expect(CookieCipher.isEncrypted(storage.values[_key]!), isTrue);
    });

    test('ignores an unusable legacy cookie', () async {
      storage.values[_key] = 'ltoken_v2=fake';

      expect(await vault.read('800000001'), isNull);
    });

    test('ignores an encrypted cookie that is no longer usable', () async {
      final cipher = CookieCipher(storage);
      storage.values[_key] = await cipher.encrypt(
        'ltoken_v2=fake',
        accountId: '800000001',
      );

      expect(await vault.read('800000001'), isNull);
    });

    test('delete removes the entry', () async {
      await vault.save('800000001', HoyolabCookie.parse(_raw));

      await vault.delete('800000001');

      expect(storage.values.containsKey(_key), isFalse);
    });

    test('platform errors become UnknownException', () async {
      storage.failing = true;

      await expectLater(
        vault.read('1'),
        throwsA(isA<UnknownException>()),
      );
      await expectLater(vault.delete('1'), throwsA(isA<UnknownException>()));
    });

    test('provider builds a vault', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(cookieVaultProvider), isA<CookieVault>());
    });
  });

  group('PendingCookies', () {
    test('holds cookies in memory under a pending id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final pending = container.read(pendingCookiesProvider);
      final id = PendingCookies.idFor('800000001');

      pending.put(id, _raw);

      expect(id, 'pending:800000001');
      expect(PendingCookies.isPending(id), isTrue);
      expect(PendingCookies.isPending('800000001'), isFalse);
      expect(pending.read(id), _raw);
      pending.remove(id);
      expect(pending.read(id), isNull);
    });
  });
}
