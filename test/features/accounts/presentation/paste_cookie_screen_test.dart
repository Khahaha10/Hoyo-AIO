import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/error/app_exception_l10n.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/storage/pending_cookies.dart';
import 'package:hoyo_aio/features/accounts/data/account_repository_impl.dart';
import 'package:hoyo_aio/features/accounts/presentation/paste_cookie_screen.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/pending_account_provider.dart';
import 'package:material_ui/material_ui.dart';

import '../_support/account_fakes.dart';

void main() {
  late FakeAccountRepository repository;
  late ProviderContainer container;
  late List<String?> clipboardWrites;
  String? clipboardText;

  setUp(() {
    repository = FakeAccountRepository(roles: [detectedRole(Game.genshin)]);
    container = ProviderContainer(
      overrides: [accountRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    clipboardWrites = [];
    clipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          switch (call.method) {
            case 'Clipboard.getData':
              return clipboardText == null ? null : {'text': clipboardText};
            case 'Clipboard.setData':
              final args = call.arguments as Map<Object?, Object?>;
              clipboardWrites.add(args['text'] as String?);
              return null;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
  });

  Future<RouteLog> pump(WidgetTester tester) =>
      pumpRouted(tester, const PasteCookieScreen(), container: container);

  AppButton verifyButton(WidgetTester tester) => tester.widget<AppButton>(
    find.widgetWithText(AppButton, enL10n.pasteCookieVerify),
  );

  String fieldText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  testWidgets('empty field shows no badge and disables Verify', (tester) async {
    await pump(tester);

    expect(find.byType(AppBadge), findsNothing);
    expect(verifyButton(tester).onPressed, isNull);
    expect(find.text(enL10n.pasteCookieTitle), findsOneWidget);
  });

  testWidgets('cookie without token shows the missing-keys warning', (
    tester,
  ) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'ltuid_v2=$fakeUid');
    await tester.pump();

    expect(find.text(enL10n.pasteCookieMissing), findsOneWidget);
    expect(verifyButton(tester).onPressed, isNull);
  });

  testWidgets('usable cookie shows the key count and enables Verify', (
    tester,
  ) async {
    await pump(tester);

    await tester.enterText(
      find.byType(TextField),
      '$fakeCookieText; _ga=ignored; ltmid_v2=mid',
    );
    await tester.pump();

    expect(find.text(enL10n.pasteCookieValid(3)), findsOneWidget);
    expect(verifyButton(tester).onPressed, isNotNull);
  });

  testWidgets(
    'verify keeps the cookie in memory, clears field and clipboard, opens roles',
    (tester) async {
      clipboardText = fakeCookieText;
      final log = await pump(tester);

      await tester.tap(find.text(enL10n.pasteCookiePaste));
      await tester.pump();
      expect(fieldText(tester), fakeCookieText);

      await tester.tap(find.text(enL10n.pasteCookieVerify));
      await tester.pumpAndSettle();

      expect(log.pushed, [AppRoutes.selectRoles]);
      expect(clipboardWrites, ['']);
      expect(repository.saved, isEmpty);
      final pendingId = PendingCookies.idFor(fakeUid);
      expect(
        container.read(pendingCookiesProvider).read(pendingId),
        fakeCookieText,
      );
      expect(
        container.read(pendingAccountControllerProvider)?.hoyolabUid,
        fakeUid,
      );
      final field = tester.widget<TextField>(
        find.byType(TextField, skipOffstage: false),
      );
      expect(field.controller!.text, isEmpty);
    },
  );

  testWidgets('typed cookie is verified without touching the clipboard', (
    tester,
  ) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), fakeCookieText);
    await tester.pump();
    await tester.tap(find.text(enL10n.pasteCookieVerify));
    await tester.pumpAndSettle();

    expect(clipboardWrites, isEmpty);
  });

  testWidgets('empty clipboard leaves the field unchanged', (tester) async {
    await pump(tester);

    await tester.tap(find.text(enL10n.pasteCookiePaste));
    await tester.pump();

    expect(fieldText(tester), isEmpty);
  });

  testWidgets('failed verify shows the localized error and keeps the field', (
    tester,
  ) async {
    repository.detectError = const CookieExpiredException();
    final log = await pump(tester);

    await tester.enterText(find.byType(TextField), fakeCookieText);
    await tester.pump();
    await tester.tap(find.text(enL10n.pasteCookieVerify));
    await tester.pumpAndSettle();

    expect(
      find.text(const CookieExpiredException().localizedMessage(enL10n)),
      findsOneWidget,
    );
    expect(log.pushed, isEmpty);
    expect(fieldText(tester), fakeCookieText);
    expect(
      container
          .read(pendingCookiesProvider)
          .read(PendingCookies.idFor(fakeUid)),
      isNull,
    );

    await tester.enterText(find.byType(TextField), '$fakeCookieText; x=1');
    await tester.pump();
    expect(
      find.text(const CookieExpiredException().localizedMessage(enL10n)),
      findsNothing,
    );
  });
}
