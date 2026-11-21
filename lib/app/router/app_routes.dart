abstract final class AppRoutes {
  static const dashboard = '/dashboard';
  static const checkIn = '/check-in';
  static const widgets = '/widgets';
  static const settings = '/settings';
  static const onboarding = '/onboarding';
  static const gallery = '/gallery';
  static const apiDebug = '/debug/api';

  static const reachableWithoutAccount = {onboarding, gallery, apiDebug};

  static const gameParam = 'game';
  static const roleParam = 'role';
}
