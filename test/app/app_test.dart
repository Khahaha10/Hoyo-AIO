import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/app.dart';
import 'package:hoyo_aio/app/flavor.dart';
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
}
