import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:hoyo_aio/app/app_settings_provider.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/app/flavor_provider.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/has_accounts_provider.dart';
import 'package:material_ui/material_ui.dart';

List<Override> appOverrides({
  required Flavor flavor,
  bool hasAccounts = false,
  bool onboardingSeen = true,
}) => [
  flavorProvider.overrideWithValue(flavor),
  hasAccountsProvider.overrideWith((_) => Stream.value(hasAccounts)),
  appPreferencesProvider.overrideWith(
    (_) => Stream.value(
      AppPreferences(
        themeMode: ThemeMode.system,
        locale: null,
        onboardingSeen: onboardingSeen,
      ),
    ),
  ),
];

Widget withAppScope(
  Widget child, {
  required Flavor flavor,
  bool hasAccounts = false,
}) => ProviderScope(
  overrides: appOverrides(flavor: flavor, hasAccounts: hasAccounts),
  child: child,
);
