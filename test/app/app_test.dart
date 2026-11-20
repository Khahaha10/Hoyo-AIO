import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/app.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/app_colors.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final flavor in Flavor.values) {
    testWidgets('App uses the ${flavor.name} title', (tester) async {
      await tester.pumpWidget(App(flavor: flavor));

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, flavor.appTitle);
      expect(app.debugShowCheckedModeBanner, flavor == Flavor.dev);
    });
  }

  testWidgets('App follows the system theme with light and dark tokens', (
    tester,
  ) async {
    await tester.pumpWidget(const App(flavor: Flavor.prod));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(app.theme?.extension<AppColors>(), same(AppColors.light));
    expect(app.darkTheme?.extension<AppColors>(), same(AppColors.dark));
  });
}
