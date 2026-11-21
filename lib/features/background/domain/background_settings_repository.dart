abstract interface class BackgroundSettingsRepository {
  Stream<int> watchRefreshMinutes();

  Future<void> setRefreshMinutes(int minutes);
}
