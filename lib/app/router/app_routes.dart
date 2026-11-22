abstract final class AppRoutes {
  static const dashboard = '/dashboard';
  static const checkIn = '/check-in';
  static const databook = '/databook';
  static const characters = '/databook/characters';
  static const endgame = '/databook/endgame';
  static const modeParam = 'mode';
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
  static const about = '/about';
  static const inbox = '/inbox';
  static const codes = '/codes';
  static const tracker = '/tracker';
  static const trackerHistoryPath = '/tracker/history';
  static const bannerParam = 'banner';

  static String trackerFor(Enum game) => '$tracker?$gameParam=${game.name}';

  static String trackerHistory(Enum game, String banner) =>
      '$trackerHistoryPath?$gameParam=${game.name}&$bannerParam=$banner';
  static const tabParam = 'tab';
  static const eventsTab = 'events';
  static const events = '$codes?$tabParam=$eventsTab';
  static const widgetEditorPath = '/widgets/edit';
  static const widgetIdParam = 'id';
  static const widgetSizeParam = 'size';

  static String widgetEditor(int widgetId, Enum size) =>
      '$widgetEditorPath?$widgetIdParam=$widgetId&$widgetSizeParam=${size.name}';
  static const gallery = '/gallery';
  static const apiDebug = '/debug/api';
  static const chronicleProbe = '/debug/chronicle';

  static const devTools = {gallery, apiDebug, chronicleProbe};
  static const entryFlow = {splash, onboarding, addAccount};

  static const gameParam = 'game';
  static const roleParam = 'role';
}
