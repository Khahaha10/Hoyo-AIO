import 'package:hoyo_aio/core/storage/hoyolab_cookie.dart';
import 'package:hoyo_aio/features/accounts/domain/detected_role.dart';

abstract interface class AccountRepository {
  Future<List<DetectedRole>> detectRoles({
    required String accountId,
    required String hoyolabUid,
  });

  Future<void> saveAccount({
    required String accountId,
    required HoyolabCookie cookie,
    required List<DetectedRole> roles,
    required Set<DetectedRole> selected,
  });
}
