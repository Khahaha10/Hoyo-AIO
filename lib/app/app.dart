import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/app/router/app_router.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

class App extends StatefulWidget {
  const App({required this.flavor, super.key});

  final Flavor flavor;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router = buildAppRouter(widget.flavor);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: widget.flavor.appTitle,
      debugShowCheckedModeBanner: widget.flavor == Flavor.dev,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: _router,
    );
  }
}
