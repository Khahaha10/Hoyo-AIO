import 'package:hoyo_aio/features/accounts/data/account_repository_impl.dart';
import 'package:hoyo_aio/features/accounts/domain/account_summary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'accounts_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<List<AccountSummary>> accounts(Ref ref) =>
    ref.watch(accountRepositoryProvider).watchAccounts();

@Riverpod(keepAlive: true)
int accountsNeedingAttention(Ref ref) =>
    ref
        .watch(accountsProvider)
        .value
        ?.where((account) => account.needsAttention)
        .length ??
    0;

@Riverpod(keepAlive: true)
class AccountActions extends _$AccountActions {
  @override
  void build() {}

  Future<int> countWidgets(String accountId) =>
      ref.read(accountRepositoryProvider).countWidgets(accountId);

  Future<void> delete(String accountId) =>
      ref.read(accountRepositoryProvider).deleteAccount(accountId);
}
