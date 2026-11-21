import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/features/accounts/presentation/add_account_screen.dart';
import 'package:hoyo_aio/features/accounts/presentation/widgets/cookie_guide_card.dart';

import '../_support/account_fakes.dart';

void main() {
  testWidgets('Continue opens the WebView login by default', (tester) async {
    final log = await pumpRouted(
      tester,
      const AddAccountScreen(showDevTools: false),
    );

    expect(find.text('Gallery'), findsNothing);
    await tester.tap(find.text(enL10n.addAccountContinue));
    await tester.pumpAndSettle();

    expect(log.pushed, [AppRoutes.webViewLogin]);
  });

  testWidgets('choosing paste opens the paste cookie screen', (tester) async {
    final log = await pumpRouted(
      tester,
      const AddAccountScreen(showDevTools: false),
    );

    await tester.tap(find.text(enL10n.addAccountPasteTitle));
    await tester.pump();
    await tester.tap(find.text(enL10n.addAccountContinue));
    await tester.pumpAndSettle();

    expect(log.pushed, [AppRoutes.pasteCookie]);
  });

  testWidgets('webview option can be chosen again', (tester) async {
    final log = await pumpRouted(
      tester,
      const AddAccountScreen(showDevTools: false),
    );

    await tester.tap(find.text(enL10n.addAccountPasteTitle));
    await tester.tap(find.text(enL10n.addAccountWebViewTitle));
    await tester.pump();
    await tester.tap(find.text(enL10n.addAccountContinue));
    await tester.pumpAndSettle();

    expect(log.pushed, [AppRoutes.webViewLogin]);
  });

  testWidgets('Why sheet explains the cookie', (tester) async {
    await pumpRouted(tester, const AddAccountScreen(showDevTools: false));

    await tester.tap(find.text(enL10n.addAccountWhy));
    await tester.pumpAndSettle();

    expect(find.text(enL10n.whyCookieTitle), findsOneWidget);
    await tester.tap(find.text(enL10n.whyCookieClose));
    await tester.pumpAndSettle();
    expect(find.text(enL10n.whyCookieTitle), findsNothing);
  });

  testWidgets('dev tools open the gallery and API debug', (tester) async {
    final log = await pumpRouted(
      tester,
      const AddAccountScreen(showDevTools: true),
      initialLocation: '/home/screen',
    );

    expect(
      find.byWidgetPredicate(
        (w) => w is AppIconButton && w.semanticLabel == enL10n.commonBack,
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Gallery'));
    await tester.pumpAndSettle();
    expect(log.pushed, [AppRoutes.gallery]);
  });

  testWidgets('dev tools API debug button navigates', (tester) async {
    final log = await pumpRouted(
      tester,
      const AddAccountScreen(showDevTools: true),
    );

    await tester.tap(find.text('API Debug'));
    await tester.pumpAndSettle();

    expect(log.pushed, [AppRoutes.apiDebug]);
  });

  testWidgets('cookie guide card renders its steps', (tester) async {
    await pumpRouted(tester, const CookieGuideCard());

    expect(find.byType(CookieGuideCard), findsOneWidget);
  });
}
