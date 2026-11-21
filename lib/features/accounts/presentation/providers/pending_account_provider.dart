import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/storage/hoyolab_cookie.dart';
import 'package:hoyo_aio/core/storage/pending_cookies.dart';
import 'package:hoyo_aio/features/accounts/data/account_repository_impl.dart';
import 'package:hoyo_aio/features/accounts/domain/detected_role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_account_provider.freezed.dart';
part 'pending_account_provider.g.dart';

@freezed
abstract class PendingAccount with _$PendingAccount {
  const factory PendingAccount({
    required String hoyolabUid,
    required String pendingId,
    required List<DetectedRole> roles,
  }) = _PendingAccount;
}

@Riverpod(keepAlive: true)
class PendingAccountController extends _$PendingAccountController {
  static const _pendingPrefix = 'pending:';

  @override
  PendingAccount? build() => null;

  Future<PendingAccount> verify(HoyolabCookie cookie) async {
    final uid = cookie.hoyolabUid;
    if (!cookie.isUsable || uid == null) {
      throw const CookieExpiredException();
    }
    final pendingId = '$_pendingPrefix$uid';
    final cookies = ref.read(pendingCookiesProvider)
      ..put(pendingId, cookie.serialize());
    try {
      final roles = await ref
          .read(accountRepositoryProvider)
          .detectRoles(accountId: pendingId, hoyolabUid: uid);
      if (roles.isEmpty) throw const NoRolesException();
      final account = PendingAccount(
        hoyolabUid: uid,
        pendingId: pendingId,
        roles: roles,
      );
      state = account;
      return account;
    } on AppException {
      cookies.remove(pendingId);
      rethrow;
    }
  }

  void clear() {
    final current = state;
    if (current != null) {
      ref.read(pendingCookiesProvider).remove(current.pendingId);
    }
    state = null;
  }
}
