import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/app/flavor_provider.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:hoyo_aio/core/network/debug/api_debug_screen.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pump(WidgetTester tester) => tester.pumpWidget(
  ProviderScope(
    overrides: [flavorProvider.overrideWithValue(Flavor.dev)],
    child: MaterialApp(theme: AppTheme.light(), home: const ApiDebugScreen()),
  ),
);

void main() {
  testWidgets('an unusable cookie is rejected without a request', (
    tester,
  ) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), 'ltoken_v2=fake');
    await tester.tap(find.text('Fetch Game Record Card'));
    await tester.pump();

    expect(find.textContaining('Cookie not usable (keys: 1)'), findsOneWidget);
    expect(find.text('ltoken_v2=fake'), findsNothing);
  });

  testWidgets('a usable cookie shows a failure from the test HTTP client', (
    tester,
  ) async {
    await _pump(tester);

    await tester.enterText(
      find.byType(TextField),
      'ltuid_v2=800000001; ltoken_v2=fake',
    );
    await tester.tap(find.text('Fetch Game Record Card'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();

    expect(find.textContaining('Failed:'), findsOneWidget);
  });
}
