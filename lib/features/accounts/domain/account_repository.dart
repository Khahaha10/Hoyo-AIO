import 'package:hoyo_aio/features/accounts/domain/detected_role.dart';

abstract interface class AccountRepository {
  Future<List<DetectedRole>> detectRoles({
    required String accountId,
    required String hoyolabUid,
  });
}
