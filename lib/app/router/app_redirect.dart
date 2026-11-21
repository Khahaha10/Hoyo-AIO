import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/app/router/deep_link.dart';

String? resolveRedirect({
  required Uri uri,
  required bool? hasAccounts,
  required bool? onboardingSeen,
}) {
  if (DeepLink.isDeepLink(uri)) return DeepLink.toLocation(uri);
  final path = uri.path;
  if (AppRoutes.devTools.contains(path)) return null;
  if (hasAccounts == null || onboardingSeen == null) {
    return path == AppRoutes.splash ? null : AppRoutes.splash;
  }
  final target = !onboardingSeen
      ? AppRoutes.onboarding
      : !hasAccounts
      ? AppRoutes.addAccount
      : null;
  final inAccountFlow = path.startsWith(AppRoutes.accountsPrefix);
  if (target == AppRoutes.addAccount && inAccountFlow) return null;
  if (target != null) return path == target ? null : target;
  if (inAccountFlow) return null;
  return AppRoutes.entryFlow.contains(path) ? AppRoutes.dashboard : null;
}
