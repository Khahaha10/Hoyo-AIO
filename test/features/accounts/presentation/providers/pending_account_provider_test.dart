import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/storage/hoyolab_cookie.dart';
import 'package:hoyo_aio/core/storage/pending_cookies.dart';
import 'package:hoyo_aio/features/accounts/data/account_repository_impl.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/pending_account_provider.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/has_accounts_provider.dart';

import '../../_support/account_fakes.dart';

void main() {
  late FakeAccountRepository repository;
  late ProviderContainer container;
  final cookie = HoyolabCookie.parse(fakeCookieText);
  final gi = detectedRole(Game.genshin);
  final zzz = detectedRole(Game.zzz);
  const pendingId = '${PendingCookies.idPrefix}$fakeUid';

  setUp(() {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    repository = FakeAccountRepository(roles: [gi, zzz]);
    container = ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(repository),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);
    container.listen(hasAccountsProvider, (_, _) {});
  });

  PendingAccountController controller() =>
      container.read(pendingAccountControllerProvider.notifier);

  PendingCookies pending() => container.read(pendingCookiesProvider);

  test('starts empty', () {
    expect(container.read(pendingAccountControllerProvider), isNull);
  });

  test('verify keeps the cookie in memory under a pending id', () async {
    final account = await controller().verify(cookie);

    expect(account.hoyolabUid, fakeUid);
    expect(account.pendingId, pendingId);
    expect(account.roles, [gi, zzz]);
    expect(container.read(pendingAccountControllerProvider), account);
    expect(repository.detectCalls, [pendingId]);
    expect(pending().read(pendingId), cookie.serialize());
    expect(repository.saved, isEmpty);
  });

  test('verify rejects a cookie without uid or token', () async {
    await expectLater(
      controller().verify(HoyolabCookie.parse('ltoken_v2=fake')),
      throwsA(isA<CookieExpiredException>()),
    );
    expect(repository.detectCalls, isEmpty);
  });

  test('verify drops the pending cookie when no roles are found', () async {
    repository.roles = const [];

    await expectLater(
      controller().verify(cookie),
      throwsA(isA<NoRolesException>()),
    );
    expect(pending().read(pendingId), isNull);
    expect(container.read(pendingAccountControllerProvider), isNull);
  });

  test('verify drops the pending cookie when the API fails', () async {
    repository.detectError = const CookieExpiredException();

    await expectLater(
      controller().verify(cookie),
      throwsA(isA<CookieExpiredException>()),
    );
    expect(pending().read(pendingId), isNull);
  });

  test('confirm saves under the HoYoLAB uid and clears memory', () async {
    await controller().verify(cookie);

    await controller().confirm({zzz});

    final saved = repository.saved.single;
    expect(saved.accountId, fakeUid);
    expect(saved.cookie, cookie.serialize());
    expect(saved.selected, {zzz});
    expect(container.read(pendingAccountControllerProvider), isNull);
    expect(pending().read(pendingId), isNull);
  });

  test('confirm without a pending account throws CookieExpiredException', () async {
    await expectLater(
      controller().confirm({gi}),
      throwsA(isA<CookieExpiredException>()),
    );
  });

  test('confirm with an empty selection throws NoRolesException', () async {
    await controller().verify(cookie);

    await expectLater(
      controller().confirm({}),
      throwsA(isA<NoRolesException>()),
    );
    expect(repository.saved, isEmpty);
    expect(pending().read(pendingId), isNotNull);
  });

  test('clear forgets the pending account and cookie', () async {
    await controller().verify(cookie);

    controller().clear();

    expect(container.read(pendingAccountControllerProvider), isNull);
    expect(pending().read(pendingId), isNull);
  });

  test('PendingCookies recognises pending ids', () {
    expect(PendingCookies.isPending(pendingId), isTrue);
    expect(PendingCookies.isPending(fakeUid), isFalse);
  });
}
