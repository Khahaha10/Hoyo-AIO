enum NotificationKind {
  stamina,
  expeditions,
  currency,
  transformer,
  dailyReminder,
  checkInResult,
  cookieExpired;

  String get channelId => 'hoyo_aio_$name';
}
