import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/accounts/domain/account_summary.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_role_provider.g.dart';

const dashboardGames = [Game.genshin, Game.starRail, Game.zzz];

List<SavedRole> _dashboardRoles(List<AccountSummary> accounts) => [
  for (final healthy in [true, false])
    for (final account in accounts)
      if (account.needsAttention != healthy)
        for (final role in account.enabledRoles)
          if (dashboardGames.contains(role.game)) role,
];

@Riverpod(keepAlive: true)
List<SavedRole> dashboardRoles(Ref ref) =>
    _dashboardRoles(ref.watch(accountsProvider).value ?? const []);

@Riverpod(keepAlive: true)
class SelectedRoleId extends _$SelectedRoleId {
  @override
  int? build() => null;

  void select(int roleId) => state = roleId;

  void selectGame(Game game) {
    final current = ref.read(selectedRoleProvider);
    final candidates = [
      for (final role in ref.read(dashboardRolesProvider))
        if (role.game == game) role,
    ];
    final match =
        candidates
            .where((role) => role.accountId == current?.accountId)
            .firstOrNull ??
        candidates.firstOrNull;
    if (match != null) state = match.id;
  }
}

@Riverpod(keepAlive: true)
SavedRole? selectedRole(Ref ref) {
  final roles = ref.watch(dashboardRolesProvider);
  final chosen = ref.watch(selectedRoleIdProvider);
  return roles.where((role) => role.id == chosen).firstOrNull ??
      roles.firstOrNull;
}
