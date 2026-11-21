import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/no_stretch_scroll_behavior.dart';
import 'package:hoyo_aio/app/router/app_shell.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

class _Counter extends StatefulWidget {
  const _Counter(this.name);

  final String name;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  var _taps = 0;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => setState(() => _taps++),
    child: Text('${widget.name} $_taps'),
  );
}

GoRouter _router() => GoRouter(
  initialLocation: '/a',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(navigationShell: shell),
      branches: [
        for (final name in ['a', 'b', 'c', 'd'])
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/$name', builder: (_, _) => _Counter(name)),
            ],
          ),
      ],
    ),
  ],
);

void main() {
  testWidgets('bottom nav switches tabs and keeps each tab state', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        scrollBehavior: const NoStretchScrollBehavior(),
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('a 0'));
    await tester.pump();
    await tester.tap(find.text('Check-in'));
    await tester.pumpAndSettle();
    expect(find.text('b 0'), findsOneWidget);

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('a 1'), findsOneWidget);

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('Widgets'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('NoStretchScrollBehavior draws no overscroll indicator', (
    tester,
  ) async {
    late Widget built;
    const child = SizedBox();
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          built = const NoStretchScrollBehavior().buildOverscrollIndicator(
            context,
            child,
            ScrollableDetails.vertical(controller: ScrollController()),
          );
          return const SizedBox();
        },
      ),
    );

    expect(built, same(child));
  });
}
