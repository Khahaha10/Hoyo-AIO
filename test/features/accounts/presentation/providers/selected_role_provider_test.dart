import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/accounts/data/account_repository_impl.dart';
import 'package:hoyo_aio/features/accounts/domain/account_summary.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/has_accounts_provider.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/selected_role_provider.dart';

import '../../_support/account_fakes.dart';

Future<ProviderContainer> _containerWith(List<AccountSummary> accounts) async {
  final container = ProviderContainer(
    overrides: [
      accountRepositoryProvider.overrideWithValue(
        FakeAccountRepository(accounts: accounts),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.listen(accountsProvider, (_, _) {});
  await container.read(accountsProvider.future);
  return container;
}

void main() {
  final healthy = accountSummary(
    roles: [
      savedRole(1, Game.genshin),
      savedRole(2, Game.hi3),
      savedRole(3, Game.zzz, enabled: false),
      savedRole(4, Game.starRail),
    ],
  );
  final expired = accountSummary(
    id: '800000002',
    status: AccountStatus.expired,
    roles: [
      savedRole(5, Game.genshin, accountId: '800000002'),
      savedRole(6, Game.zzz, accountId: '800000002'),
    ],
  );

  test('dashboard roles skip HI3 and disabled roles, healthy first', () async {
    final container = await _containerWith([expired, healthy]);

    final ids = container.read(dashboardRolesProvider).map((r) => r.id);

    expect(ids, [1, 4, 5, 6]);
  });

  test('selected role falls back to the first dashboard role', () async {
    final container = await _containerWith([healthy]);

    expect(container.read(selectedRoleProvider)?.id, 1);
  });

  test('select picks a role and unknown ids fall back', () async {
    final container = await _containerWith([healthy, expired]);
    container.listen(selectedRoleProvider, (_, _) {});

    container.read(selectedRoleIdProvider.notifier).select(4);
    expect(container.read(selectedRoleProvider)?.id, 4);

    container.read(selectedRoleIdProvider.notifier).select(99);
    expect(container.read(selectedRoleProvider)?.id, 1);
  });

  test(
    'selectGame prefers the current account and ignores missing games',
    () async {
      final container = await _containerWith([healthy, expired]);
      final notifier = container.read(selectedRoleIdProvider.notifier);

      notifier.select(5);
      notifier.selectGame(Game.zzz);
      expect(container.read(selectedRoleIdProvider), 6);

      notifier.select(1);
      notifier.selectGame(Game.zzz);
      expect(container.read(selectedRoleIdProvider), 6);

      notifier.select(1);
      notifier.selectGame(Game.hi3);
      expect(container.read(selectedRoleIdProvider), 1);
    },
  );

  test('no accounts means no selected role', () async {
    final container = await _containerWith(const []);

    expect(container.read(selectedRoleProvider), isNull);
    expect(container.read(accountsNeedingAttentionProvider), 0);
  });

  test('accounts needing attention counts non-valid accounts', () async {
    final container = await _containerWith([
      healthy,
      expired,
      accountSummary(id: '3', status: AccountStatus.needsLogin),
    ]);

    expect(container.read(accountsNeedingAttentionProvider), 2);
  });

  test('account actions forward to the repository', () async {
    final repository = FakeAccountRepository(widgets: 3);
    final container = ProviderContainer(
      overrides: [accountRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final actions = container.read(accountActionsProvider.notifier);

    expect(await actions.countWidgets(fakeUid), 3);
    await actions.delete(fakeUid);

    expect(repository.deleted, [fakeUid]);
  });

  test('hasAccounts follows the accounts table', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    container.listen(hasAccountsProvider, (_, _) {});

    expect(await container.read(hasAccountsProvider.future), isFalse);
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: fakeUid,
            nickname: 'n',
            status: AccountStatus.valid,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        );
    await pumpEventQueue();

    expect(container.read(hasAccountsProvider).value, isTrue);
  });

  test('AccountSummary flags attention for non-valid statuses', () {
    expect(accountSummary().needsAttention, isFalse);
    expect(
      accountSummary(status: AccountStatus.needsLogin).needsAttention,
      isTrue,
    );
    expect(healthy.enabledRoles.map((r) => r.id), [1, 2, 4]);
  });
}
