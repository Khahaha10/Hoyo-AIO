enum NotificationKind {
  stamina,
  expeditions,
  currency,
  transformer,
  dailyReminder,
  checkInResult,
  cookieExpired,
  newCodes;

  String get channelId => 'hoyo_aio_$name';
}
