import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';

part 'account_summary.freezed.dart';

@freezed
abstract class AccountSummary with _$AccountSummary {
  const factory AccountSummary({
    required String id,
    required String nickname,
    required AccountStatus status,
    required DateTime updatedAt,
    required List<SavedRole> roles,
  }) = _AccountSummary;

  const AccountSummary._();

  bool get needsAttention => status != AccountStatus.valid;

  List<SavedRole> get enabledRoles => [
    for (final role in roles)
      if (role.enabled) role,
  ];
}
