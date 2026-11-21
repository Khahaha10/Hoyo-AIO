abstract final class AppRoutes {
  static const dashboard = '/dashboard';
  static const checkIn = '/check-in';
  static const widgets = '/widgets';
  static const settings = '/settings';
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const accountsPrefix = '/accounts';
  static const accounts = '/accounts';
  static const addAccount = '/accounts/add';
  static const pasteCookie = '/accounts/paste';
  static const webViewLogin = '/accounts/webview';
  static const selectRoles = '/accounts/roles';
  static const notifications = '/notifications';
  static const codes = '/codes';
  static const widgetEditorPath = '/widgets/edit';
  static const widgetIdParam = 'id';
  static const widgetSizeParam = 'size';

  static String widgetEditor(int widgetId, Enum size) =>
      '$widgetEditorPath?$widgetIdParam=$widgetId&$widgetSizeParam=${size.name}';
  static const gallery = '/gallery';
  static const apiDebug = '/debug/api';

  static const devTools = {gallery, apiDebug};
  static const entryFlow = {splash, onboarding, addAccount};

  static const gameParam = 'game';
  static const roleParam = 'role';
}
