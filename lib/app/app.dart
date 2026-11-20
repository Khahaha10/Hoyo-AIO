import 'package:hoyo_aio/app/flavor.dart';
import 'package:material_ui/material_ui.dart';

class App extends StatelessWidget {
  const App({required this.flavor, super.key});

  final Flavor flavor;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: flavor.appTitle,
      debugShowCheckedModeBanner: flavor == Flavor.dev,
      home: const Scaffold(body: SizedBox.shrink()),
    );
  }
}
