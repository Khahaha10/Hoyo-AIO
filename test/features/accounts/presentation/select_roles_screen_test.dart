import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/error/app_exception_l10n.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/storage/hoyolab_cookie.dart';
import 'package:hoyo_aio/features/accounts/data/account_repository_impl.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/has_accounts_provider.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/pending_account_provider.dart';
import 'package:hoyo_aio/features/accounts/presentation/select_roles_screen.dart';
import 'package:hoyo_aio/features/accounts/presentation/widgets/game_roles_card.dart';
import 'package:material_ui/material_ui.dart';

import '../_support/account_fakes.dart';

void main() {
  late FakeAccountRepository repository;
  late ProviderContainer container;
  final gi = detectedRole(Game.genshin);
  final hsr = detectedRole(Game.starRail, uid: '800000002');
  final zzz = detectedRole(Game.zzz, uid: '800000003');

  setUp(() {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    repository = FakeAccountRepository(roles: [gi, hsr, zzz]);
    container = ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(repository),
        appDatabaseProvider.overrideWithValue(db),
        hasAccountsProvider.overrideWith((_) => Stream.value(true)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(hasAccountsProvider, (_, _) {});
  });

  Future<RouteLog> pump(
    WidgetTester tester, {
    bool verified = true,
    String? initialLocation,
  }) async {
    if (verified) {
      await tester.runAsync(
        () => container
            .read(pendingAccountControllerProvider.notifier)
            .verify(HoyolabCookie.parse(fakeCookieText)),
      );
    }
    return pumpRouted(
      tester,
      const SelectRolesScreen(),
      container: container,
      initialLocation: initialLocation,
    );
  }

  AppButton addButton(WidgetTester tester, int count) =>
      tester.widget<AppButton>(
        find.widgetWithText(AppButton, enL10n.selectRolesAdd(count)),
      );

  testWidgets('lists one card per game with all roles preselected', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byType(GameRolesCard), findsNWidgets(3));
    expect(addButton(tester, 3).onPressed, isNotNull);
    expect(find.text(enL10n.selectRolesClearAll), findsOneWidget);
  });

  testWidgets('toggling a role and Select All update the count', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.textContaining('${gi.nickname} ·'));
    await tester.pump();
    expect(addButton(tester, 2).onPressed, isNotNull);
    expect(find.text(enL10n.selectRolesSelectAll), findsOneWidget);

    await tester.tap(find.text(enL10n.selectRolesSelectAll));
    await tester.pump();
    expect(find.text(enL10n.selectRolesAdd(3)), findsOneWidget);

    await tester.tap(find.text(enL10n.selectRolesClearAll));
    await tester.pump();
    expect(addButton(tester, 0).onPressed, isNull);

    await tester.tap(find.textContaining('${zzz.nickname} ·'));
    await tester.pump();
    expect(find.text(enL10n.selectRolesAdd(1)), findsOneWidget);
  });

  testWidgets('Add saves the selected roles and goes to the dashboard', (
    tester,
  ) async {
    final log = await pump(tester);

    await tester.tap(find.textContaining('${hsr.nickname} ·'));
    await tester.pump();
    await tester.tap(find.text(enL10n.selectRolesAdd(2)));
    await tester.pumpAndSettle();

    final saved = repository.saved.single;
    expect(saved.accountId, fakeUid);
    expect(saved.selected, {gi, zzz});
    expect(log.pushed, [AppRoutes.dashboard]);
    expect(container.read(pendingAccountControllerProvider), isNull);
  });

  testWidgets('save failure shows a snackbar and keeps the screen', (
    tester,
  ) async {
    repository.saveError = const NetworkException();
    final log = await pump(tester);

    await tester.tap(find.text(enL10n.selectRolesAdd(3)));
    await tester.pumpAndSettle();

    expect(
      find.text(const NetworkException().localizedMessage(enL10n)),
      findsOneWidget,
    );
    expect(log.pushed, isEmpty);
    expect(addButton(tester, 3).onPressed, isNotNull);
  });

  testWidgets('without a pending account it asks to add the account again', (
    tester,
  ) async {
    final log = await pump(tester, verified: false);

    expect(find.text(enL10n.selectRolesSessionExpired), findsOneWidget);
    await tester.tap(find.text(enL10n.addAccountTitle));
    await tester.pumpAndSettle();

    expect(log.pushed, [AppRoutes.addAccount]);
  });

  testWidgets('going back drops the pending cookie', (tester) async {
    await pump(tester, initialLocation: '/home/screen');

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is AppIconButton && w.semanticLabel == enL10n.commonBack,
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(pendingAccountControllerProvider), isNull);
    expect(repository.saved, isEmpty);
  });
}
