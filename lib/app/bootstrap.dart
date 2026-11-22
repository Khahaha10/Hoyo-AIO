import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart'
    show DeviceOrientation, SystemChrome, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/app/app.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/app/flavor_provider.dart';
import 'package:hoyo_aio/app/provider_retry.dart';
import 'package:material_ui/material_ui.dart';

const bundledLicenses = {
  'android_genshin_resin_widget':
      'assets/licenses/android_genshin_resin_widget-MIT.txt',
  'Inter': 'assets/licenses/Inter-OFL.txt',
};

void registerBundledLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: package, value: path) in bundledLicenses.entries) {
      yield LicenseEntryWithLineBreaks([
        package,
      ], await rootBundle.loadString(path));
    }
  });
}

Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  registerBundledLicenses();
  runApp(
    ProviderScope(
      retry: noProviderRetry,
      overrides: [flavorProvider.overrideWithValue(flavor)],
      child: App(flavor: flavor),
    ),
  );
}
