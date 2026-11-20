import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/app/app.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:material_ui/material_ui.dart';

void bootstrap(Flavor flavor) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(child: App(flavor: flavor)));
}
