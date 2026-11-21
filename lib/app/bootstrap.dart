import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/app/app.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/app/flavor_provider.dart';
import 'package:material_ui/material_ui.dart';

void bootstrap(Flavor flavor) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [flavorProvider.overrideWithValue(flavor)],
      child: App(flavor: flavor),
    ),
  );
}
