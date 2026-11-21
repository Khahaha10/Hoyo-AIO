import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/app/flavor_provider.dart';
import 'package:hoyo_aio/app/placeholder_screen.dart';
import 'package:hoyo_aio/app/router/app_redirect.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/app/router/app_shell.dart';
import 'package:hoyo_aio/core/design_system/gallery/gallery_screen.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/network/debug/api_debug_screen.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/has_accounts_provider.dart';
import 'package:hoyo_aio/features/onboarding/presentation/onboarding_placeholder_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final flavor = ref.watch(flavorProvider);
  final refresh = ValueNotifier<int>(0);
  ref.listen(hasAccountsProvider, (_, _) => refresh.value++);
  final router = GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: refresh,
    redirect: (_, state) => resolveRedirect(
      uri: state.uri,
      hasAccounts: ref.read(hasAccountsProvider).value,
    ),
    routes: _routes(flavor),
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
}

List<RouteBase> _routes(Flavor flavor) => [
  StatefulShellRoute.indexedStack(
    builder: (_, _, shell) => AppShell(navigationShell: shell),
    branches: [
      _branch(AppRoutes.dashboard, (context, state) {
        final params = state.uri.queryParameters;
        final game = params[AppRoutes.gameParam];
        final role = params[AppRoutes.roleParam];
        return PlaceholderScreen(
          title: context.l10n.navDashboard,
          detail: game == null
              ? null
              : context.l10n.dashboardDeepLinkTarget(game, role ?? '-'),
        );
      }),
      _branch(
        AppRoutes.checkIn,
        (context, _) => PlaceholderScreen(title: context.l10n.navCheckIn),
      ),
      _branch(
        AppRoutes.widgets,
        (context, _) => PlaceholderScreen(title: context.l10n.navWidgets),
      ),
      _branch(
        AppRoutes.settings,
        (context, _) => PlaceholderScreen(title: context.l10n.navSettings),
      ),
    ],
  ),
  GoRoute(
    path: AppRoutes.onboarding,
    builder: (_, _) =>
        OnboardingPlaceholderScreen(showDevTools: flavor.galleryEnabled),
  ),
  if (flavor.galleryEnabled) ...[
    GoRoute(path: AppRoutes.gallery, builder: (_, _) => const GalleryScreen()),
    GoRoute(
      path: AppRoutes.apiDebug,
      builder: (_, _) => const ApiDebugScreen(),
    ),
  ],
];

StatefulShellBranch _branch(
  String path,
  Widget Function(BuildContext, GoRouterState) builder,
) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: builder)],
);
