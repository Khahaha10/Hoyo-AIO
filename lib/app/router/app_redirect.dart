import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/app/router/deep_link.dart';

String? resolveRedirect({required Uri uri, required bool? hasAccounts}) {
  if (DeepLink.isDeepLink(uri)) return DeepLink.toLocation(uri);
  if (hasAccounts == null) return null;
  final path = uri.path;
  if (!hasAccounts && !AppRoutes.reachableWithoutAccount.contains(path)) {
    return AppRoutes.onboarding;
  }
  if (hasAccounts && path == AppRoutes.onboarding) return AppRoutes.dashboard;
  return null;
}
