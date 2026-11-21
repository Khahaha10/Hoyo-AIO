import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/features/settings/domain/backup_schema.dart';
import 'package:hoyo_aio/features/settings/presentation/backup_row.dart';

import '../_support/settings_support.dart';

void main() {
  Future<void> pumpRow(WidgetTester tester, FakeBackupService service) =>
      pumpRouted(
        tester,
        settingsRouter(const BackupRow()),
        overrides: settingsOverrides(backup: service),
      );

  testWidgets('export calls the backup service', (tester) async {
    final service = FakeBackupService();
    await pumpRow(tester, service);

    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();

    expect(service.calls, ['export']);
    await drainTimers(tester);
  });

  testWidgets('an invalid file shows a snackbar', (tester) async {
    final service = FakeBackupService(
      pickError: const BackupFormatException('json'),
    );
    await pumpRow(tester, service);

    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    expect(
      find.text('This file is not a HoYo AIO backup, or it is damaged.'),
      findsOneWidget,
    );
    expect(service.calls, ['pick']);
    await drainTimers(tester);
  });

  testWidgets('cancelling the file picker does nothing', (tester) async {
    final service = FakeBackupService();
    await pumpRow(tester, service);

    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    expect(service.calls, ['pick']);
    expect(find.text('Import Backup?'), findsNothing);
    await drainTimers(tester);
  });

  testWidgets('confirming applies and reports needs-login count', (
    tester,
  ) async {
    final service = FakeBackupService(picked: sampleBackup(), needsLogin: 2);
    await pumpRow(tester, service);

    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    expect(find.text('Import Backup?'), findsOneWidget);
    expect(find.textContaining('This backup has 1 account.'), findsOneWidget);

    await tester.tap(find.text('Import').last);
    await tester.pumpAndSettle();

    expect(service.calls, ['pick', 'apply']);
    expect(
      find.text('Backup imported · 2 accounts need login'),
      findsOneWidget,
    );
    await drainTimers(tester);
  });

  testWidgets('cancelling the dialog does not apply', (tester) async {
    final service = FakeBackupService(picked: sampleBackup());
    await pumpRow(tester, service);

    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(service.calls, ['pick']);
    expect(find.textContaining('Backup imported'), findsNothing);
    await drainTimers(tester);
  });
}
