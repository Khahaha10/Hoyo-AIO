import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/core/design_system/gallery/gallery_screen.dart';
import 'package:material_ui/material_ui.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const gallery = '/gallery';
}

GoRouter buildAppRouter(Flavor flavor) => GoRouter(
  initialLocation: flavor.galleryEnabled ? AppRoutes.gallery : AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
    ),
    if (flavor.galleryEnabled)
      GoRoute(
        path: AppRoutes.gallery,
        builder: (_, _) => const GalleryScreen(),
      ),
  ],
);
