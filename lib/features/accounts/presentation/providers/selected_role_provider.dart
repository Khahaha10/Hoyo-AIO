import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_role_provider.g.dart';

@Riverpod(keepAlive: true)
class SelectedRoleId extends _$SelectedRoleId {
  @override
  int? build() => null;

  void select(int roleId) => state = roleId;
}

@Riverpod(keepAlive: true)
SavedRole? selectedRole(Ref ref) {
  final accounts = ref.watch(accountsProvider).value ?? const [];
  final roles = [
    for (final account in accounts)
      if (!account.needsAttention) ...account.enabledRoles,
    for (final account in accounts)
      if (account.needsAttention) ...account.enabledRoles,
  ];
  final chosen = ref.watch(selectedRoleIdProvider);
  return roles.where((role) => role.id == chosen).firstOrNull ??
      roles.firstOrNull;
}
