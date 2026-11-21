import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/router/app_redirect.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';

String? _redirect(String location, {bool? accounts, bool? seen}) =>
    resolveRedirect(
      uri: Uri.parse(location),
      hasAccounts: accounts,
      onboardingSeen: seen,
    );

void main() {
  group('resolveRedirect', () {
    test('waits on splash until accounts and settings are loaded', () {
      expect(_redirect(AppRoutes.dashboard), AppRoutes.splash);
      expect(_redirect(AppRoutes.dashboard, accounts: true), AppRoutes.splash);
      expect(_redirect(AppRoutes.splash), isNull);
    });

    test('sends a first-time user to onboarding', () {
      expect(
        _redirect(AppRoutes.splash, accounts: false, seen: false),
        AppRoutes.onboarding,
      );
      expect(
        _redirect(AppRoutes.onboarding, accounts: false, seen: false),
        isNull,
      );
    });

    test('never shows onboarding again once seen', () {
      expect(
        _redirect(AppRoutes.onboarding, accounts: true, seen: true),
        AppRoutes.dashboard,
      );
      expect(
        _redirect(AppRoutes.onboarding, accounts: false, seen: true),
        AppRoutes.addAccount,
      );
    });

    test('without accounts the user stays in the account flow', () {
      expect(
        _redirect(AppRoutes.dashboard, accounts: false, seen: true),
        AppRoutes.addAccount,
      );
      expect(
        _redirect(AppRoutes.addAccount, accounts: false, seen: true),
        isNull,
      );
      expect(
        _redirect(AppRoutes.pasteCookie, accounts: false, seen: true),
        isNull,
      );
    });

    test('with accounts entry screens go to the dashboard', () {
      for (final path in [AppRoutes.splash, AppRoutes.onboarding]) {
        expect(
          _redirect(path, accounts: true, seen: true),
          AppRoutes.dashboard,
        );
      }
      expect(_redirect(AppRoutes.accounts, accounts: true, seen: true), isNull);
      expect(
        _redirect(AppRoutes.addAccount, accounts: true, seen: true),
        isNull,
      );
      expect(_redirect(AppRoutes.settings, accounts: true, seen: true), isNull);
    });

    test('dev tools are never redirected', () {
      expect(_redirect(AppRoutes.gallery), isNull);
      expect(_redirect(AppRoutes.apiDebug, accounts: false, seen: false), isNull);
    });

    test('deep links resolve to a dashboard location', () {
      expect(
        _redirect('hoyoaio://dashboard?game=zzz', accounts: true, seen: true),
        '/dashboard?game=zzz',
      );
    });
  });
}
