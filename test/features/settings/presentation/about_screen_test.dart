import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/features/settings/presentation/about_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../_support/settings_support.dart';

GoRouter _router() => GoRouter(
  initialLocation: AppRoutes.about,
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const Scaffold(body: Text('home')),
      routes: [GoRoute(path: 'about', builder: (_, _) => const AboutScreen())],
    ),
  ],
);

void main() {
  testWidgets('shows version, disclaimer and credits', (tester) async {
    await pumpRouted(tester, _router(), overrides: settingsOverrides());

    expect(find.text('Version 1.0.0 (1)'), findsOneWidget);
    expect(find.text('Disclaimer'), findsOneWidget);
    expect(
      find.textContaining('HoYo AIO is an unofficial fan-made app.'),
      findsOneWidget,
    );
    expect(find.textContaining('android_genshin_resin_widget'), findsOneWidget);
    await drainTimers(tester);
  });

  testWidgets('back button returns to the previous page', (tester) async {
    await pumpRouted(tester, _router(), overrides: settingsOverrides());

    await tester.tap(find.byType(AppIconButton));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    await drainTimers(tester);
  });

  testWidgets('open-source licenses opens the license page', (tester) async {
    await pumpRouted(tester, _router(), overrides: settingsOverrides());

    await tester.ensureVisible(find.text('Open-Source Licenses'));
    await tester.tap(find.text('Open-Source Licenses'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(LicensePage), findsOneWidget);
    await drainTimers(tester);
  });
}
