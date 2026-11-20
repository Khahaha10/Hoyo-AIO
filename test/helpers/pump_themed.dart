import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

Future<void> pumpThemed(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  bool disableAnimations = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      debugShowCheckedModeBanner: false,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}
