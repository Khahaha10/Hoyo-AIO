import 'package:drift/drift.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_controller.g.dart';

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  void build() {}

  Future<void> complete() async {
    final db = ref.read(appDatabaseProvider);
    await (db.update(db.appSettings)..where((s) => s.id.equals(1))).write(
      const AppSettingsCompanion(onboardingSeen: Value(true)),
    );
  }
}
