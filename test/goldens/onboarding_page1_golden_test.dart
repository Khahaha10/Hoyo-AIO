@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/features/onboarding/presentation/onboarding_screen.dart';

import '../features/onboarding/_support/pump_onboarding.dart';

void main() {
  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';
    testWidgets('onboarding page 1 $theme', (tester) async {
      final db = openMemoryDatabase();
      addTearDown(db.close);

      await pumpScreen(tester, const OnboardingScreen(), db: db, dark: dark);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(OnboardingScreen),
        matchesGoldenFile('onboarding_page1_$theme.png'),
      );
    });
  }
}
