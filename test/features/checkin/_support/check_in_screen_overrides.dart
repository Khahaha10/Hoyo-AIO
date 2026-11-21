import 'package:flutter_riverpod/misc.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/app/flavor_provider.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/accounts/domain/account_summary.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:hoyo_aio/features/checkin/data/check_in_history_repository_impl.dart';
import 'package:hoyo_aio/features/checkin/data/check_in_repository_impl.dart';

import 'fake_check_in_repositories.dart';

final checkInNow = DateTime(2026, 11, 5, 8);

List<Override> checkInScreenOverrides({
  required List<AccountSummary> accounts,
  required FakeCheckInRepository checkIn,
  required FakeCheckInHistoryRepository history,
  Flavor flavor = Flavor.prod,
}) => [
  flavorProvider.overrideWithValue(flavor),
  accountsProvider.overrideWith((_) => Stream.value(accounts)),
  checkInRepositoryProvider.overrideWithValue(checkIn),
  checkInHistoryRepositoryProvider.overrideWithValue(history),
  clockProvider.overrideWithValue(() => checkInNow),
  clockTickProvider.overrideWith((_) => Stream.value(checkInNow)),
];
