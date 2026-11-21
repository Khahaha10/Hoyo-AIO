import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/features/onboarding/presentation/onboarding_screen.dart';
import 'package:hoyo_aio/features/onboarding/presentation/splash_screen.dart';
import 'package:hoyo_aio/features/onboarding/presentation/widgets/page_dots.dart';
import 'package:material_ui/material_ui.dart';

import '../_support/pump_onboarding.dart';

Future<bool> _seen(AppDatabase db) async =>
    (await db.select(db.appSettings).getSingle()).onboardingSeen;

void main() {
  group('OnboardingScreen', () {
    testWidgets('starts on page 1 with Skip and Next', (tester) async {
      final db = openMemoryDatabase();
      addTearDown(db.close);

      await pumpScreen(tester, const OnboardingScreen(), db: db);

      expect(find.text('1 OF 3'), findsOneWidget);
      expect(find.text('Real-time Game Notes'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(tester.widget<PageDots>(find.byType(PageDots)).index, 0);
    });

    testWidgets('Next walks through all pages and Get Started finishes', (
      tester,
    ) async {
      final db = openMemoryDatabase();
      addTearDown(db.close);
      await pumpScreen(tester, const OnboardingScreen(), db: db);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('2 OF 3'), findsOneWidget);
      expect(find.text('Widgets On Your Home Screen'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('3 OF 3'), findsOneWidget);
      expect(find.text('Skip'), findsNothing);
      expect(await _seen(db), isFalse);

      await tester.tap(find.text('Get Started'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(await tester.runAsync(() => _seen(db)), isTrue);
    });

    testWidgets('reduce motion jumps to the next page', (tester) async {
      final db = openMemoryDatabase();
      addTearDown(db.close);
      await pumpScreen(
        tester,
        const OnboardingScreen(),
        db: db,
        disableAnimations: true,
      );

      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(find.text('2 OF 3'), findsOneWidget);
    });

    testWidgets('swiping changes the page', (tester) async {
      final db = openMemoryDatabase();
      addTearDown(db.close);
      await pumpScreen(tester, const OnboardingScreen(), db: db);

      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(find.text('2 OF 3'), findsOneWidget);
    });

    testWidgets('Skip marks onboarding as seen so it is shown once', (
      tester,
    ) async {
      final db = openMemoryDatabase();
      addTearDown(db.close);
      await pumpScreen(tester, const OnboardingScreen(), db: db);

      await tester.tap(find.text('Skip'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(await tester.runAsync(() => _seen(db)), isTrue);
    });
  });

  group('SplashScreen', () {
    for (final reduceMotion in [false, true]) {
      testWidgets('shows name, tagline and disclaimer (reduce motion: '
          '$reduceMotion)', (tester) async {
        final db = openMemoryDatabase();
        addTearDown(db.close);

        await pumpScreen(
          tester,
          const SplashScreen(),
          db: db,
          disableAnimations: reduceMotion,
        );
        await tester.pumpAndSettle();

        expect(find.text('HoYo AIO'), findsOneWidget);
        expect(find.text('Your game notes, all in one place'), findsOneWidget);
        expect(
          find.textContaining('Not affiliated with HoYoverse'),
          findsOneWidget,
        );
      });
    }
  });
}
