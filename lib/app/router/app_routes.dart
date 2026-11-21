abstract final class AppRoutes {
  static const dashboard = '/dashboard';
  static const checkIn = '/check-in';
  static const widgets = '/widgets';
  static const settings = '/settings';
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const addAccount = '/accounts/add';
  static const gallery = '/gallery';
  static const apiDebug = '/debug/api';

  static const devTools = {gallery, apiDebug};
  static const entryFlow = {splash, onboarding, addAccount};

  static const gameParam = 'game';
  static const roleParam = 'role';
}
