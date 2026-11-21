import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'has_accounts_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<bool> hasAccounts(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(
    db.accounts,
  )..limit(1)).watch().map((rows) => rows.isNotEmpty);
}
