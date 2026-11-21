import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/design_system/components/skeleton.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/error/app_exception_l10n.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/accounts/data/account_repository_impl.dart';
import 'package:hoyo_aio/features/accounts/domain/account_summary.dart';
import 'package:hoyo_aio/features/accounts/presentation/accounts_screen.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:hoyo_aio/features/accounts/presentation/widgets/account_card.dart';
import 'package:hoyo_aio/features/accounts/presentation/widgets/role_chip.dart';
import 'package:material_ui/material_ui.dart';

import '../_support/account_fakes.dart';

void main() {
  final valid = accountSummary(
    roles: [
      savedRole(1, Game.genshin),
      savedRole(2, Game.starRail, enabled: false),
      savedRole(3, Game.hi3),
    ],
  );
  final expired = accountSummary(
    id: '800000002',
    nickname: 'Expired One',
    status: AccountStatus.expired,
  );
  final imported = accountSummary(
    id: '800000003',
    nickname: '',
    status: AccountStatus.needsLogin,
  );

  Future<RouteLog> pump(
    WidgetTester tester,
    FakeAccountRepository repository, {
    Stream<List<AccountSummary>>? stream,
  }) {
    return pumpRouted(
      tester,
      const AccountsScreen(),
      initialLocation: "/home/screen",
      size: const Size(1236, 3200),
      overrides: [
        accountRepositoryProvider.overrideWithValue(repository),
        if (stream != null) accountsProvider.overrideWith((_) => stream),
      ],
    );
  }

  testWidgets('shows a card per account with status badge and enabled roles', (
    tester,
  ) async {
    await pump(
      tester,
      FakeAccountRepository(accounts: [valid, expired, imported]),
    );
    await tester.pump();

    expect(find.byType(AccountCard), findsNWidgets(3));
    expect(find.text(enL10n.accountStatusValid), findsOneWidget);
    expect(find.text(enL10n.accountStatusExpired), findsOneWidget);
    expect(find.text(enL10n.accountStatusNeedsLogin), findsOneWidget);
    expect(find.byType(RoleChip), findsNWidgets(2));
    expect(find.text(enL10n.accountsNoRoles), findsNWidgets(2));
    expect(find.text(enL10n.accountsMetaNeedsLogin), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('shows a skeleton while loading and an error on failure', (
    tester,
  ) async {
    final controller = StreamController<List<AccountSummary>>();
    addTearDown(controller.close);
    await pump(tester, FakeAccountRepository(), stream: controller.stream);

    expect(find.byType(Skeleton), findsOneWidget);

    controller.addError(const NetworkException());
    await tester.pump();
    await tester.pump();

    expect(
      find.text(const NetworkException().localizedMessage(enL10n)),
      findsOneWidget,
    );
  });

  testWidgets('unknown errors show the generic message', (tester) async {
    await pump(
      tester,
      FakeAccountRepository(),
      stream: Stream.error(StateError('boom')),
    );
    await tester.pump();

    expect(find.text(enL10n.errorUnknown), findsOneWidget);
  });

  testWidgets('Refresh Cookie and Add Account open the add flow', (
    tester,
  ) async {
    final log = await pump(tester, FakeAccountRepository(accounts: [valid]));
    await tester.pump();

    await tester.tap(find.text(enL10n.accountsRefreshCookie));
    await tester.pumpAndSettle();

    expect(log.pushed, [AppRoutes.addAccount]);
  });

  testWidgets('delete dialog shows counts and cancel keeps the account', (
    tester,
  ) async {
    final repository = FakeAccountRepository(accounts: [valid], widgets: 2);
    await pump(tester, repository);
    await tester.pump();

    await tester.tap(find.text(enL10n.accountsDelete));
    await tester.pumpAndSettle();

    expect(find.text(enL10n.deleteAccountTitle(valid.nickname)), findsOneWidget);
    expect(find.text(enL10n.deleteAccountBody(3, 2)), findsOneWidget);

    await tester.tap(find.text(enL10n.commonCancel));
    await tester.pumpAndSettle();

    expect(repository.deleted, isEmpty);
  });

  testWidgets('confirming the dialog deletes and shows a snackbar', (
    tester,
  ) async {
    final repository = FakeAccountRepository(accounts: [valid]);
    await pump(tester, repository);
    await tester.pump();

    await tester.tap(find.text(enL10n.accountsDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(enL10n.accountsDelete).last);
    await tester.pumpAndSettle();

    expect(repository.deleted, [fakeUid]);
    expect(find.text(enL10n.accountsDeleted(valid.nickname)), findsOneWidget);
  });

  testWidgets('a failed delete shows the error snackbar', (tester) async {
    final repository = FakeAccountRepository(accounts: [valid])
      ..deleteError = const UnknownException('db');
    await pump(tester, repository);
    await tester.pump();

    await tester.tap(find.text(enL10n.accountsDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(enL10n.accountsDelete).last);
    await tester.pumpAndSettle();

    expect(
      find.text(const UnknownException('db').localizedMessage(enL10n)),
      findsOneWidget,
    );
  });
}
