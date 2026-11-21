import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/tracker/data/authkey_vault.dart';
import 'package:hoyo_aio/features/tracker/domain/gacha_link.dart';

import '../_support/tracker_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterSecureStorage storage;
  late AuthkeyVault vault;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = const FlutterSecureStorage();
    vault = AuthkeyVault(storage);
  });

  GachaLink link() => GachaLink.parse(genshinLink(), testNow)!;

  test('stores the link encrypted, never the plain authkey', () async {
    await vault.save(link());

    final stored = await storage.readAll();
    final value = stored['gacha_authkey.genshin'];
    expect(value, startsWith('v1:'));
    expect(stored.values.join(), isNot(contains(fakeAuthkey)));
  });

  test('reads the link back while it is valid', () async {
    await vault.save(link());

    final read = await vault.read(Game.genshin, testNow);

    expect(read?.game, Game.genshin);
    expect(read?.params, link().params);
    expect(read?.expiresAt, link().expiresAt.toUtc());
  });

  test('returns null when nothing is stored', () async {
    expect(await vault.read(Game.starRail, testNow), isNull);
  });

  test('drops the link once 24 hours have passed', () async {
    await vault.save(link());

    final read = await vault.read(
      Game.genshin,
      testNow.add(const Duration(hours: 24)),
    );

    expect(read, isNull);
    expect(await storage.read(key: 'gacha_authkey.genshin'), isNull);
  });

  test('drops a value that cannot be decrypted', () async {
    await storage.write(key: 'gacha_authkey.genshin', value: 'plain');

    expect(await vault.read(Game.genshin, testNow), isNull);
    expect(await storage.read(key: 'gacha_authkey.genshin'), isNull);
  });

  test('a link saved for one game cannot be read as another', () async {
    await vault.save(link());
    final sealed = await storage.read(key: 'gacha_authkey.genshin');
    await storage.write(key: 'gacha_authkey.zzz', value: sealed);

    expect(await vault.read(Game.zzz, testNow), isNull);
  });

  test('delete removes the link', () async {
    await vault.save(link());

    await vault.delete(Game.genshin);

    expect(await vault.read(Game.genshin, testNow), isNull);
  });

  test('maps broken stored base64 to ParseException', () async {
    await storage.write(key: 'hoyolab_cookie_key.v1', value: '%%%');

    expect(() => vault.save(link()), throwsA(isA<ParseException>()));
  });

  test('provider builds a vault', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(authkeyVaultProvider), isA<AuthkeyVault>());
  });
}
