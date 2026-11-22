enum NotificationKind {
  stamina,
  expeditions,
  currency,
  transformer,
  dailyReminder,
  checkInResult,
  cookieExpired,
  newCodes,
  newEvents,
  eventEnding,
  endgameReset;

  String get channelId => 'hoyo_aio_$name';
}
