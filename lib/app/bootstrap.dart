import 'package:hoyo_aio/app/app.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:material_ui/material_ui.dart';

void bootstrap(Flavor flavor) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App(flavor: flavor));
}
