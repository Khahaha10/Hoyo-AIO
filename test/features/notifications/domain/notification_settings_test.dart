import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_kind.dart';
import 'package:hoyo_aio/features/notifications/domain/notification_settings.dart';

void main() {
  test('defaults count eight alerts including cookie expired', () {
    expect(const NotificationSettings().activeAlertCount, 8);
  });

  test('turning alerts off lowers the count to the locked one', () {
    const settings = NotificationSettings(
      stamina: false,
      expeditions: false,
      currency: false,
      transformer: false,
      checkInResult: false,
      codes: false,
      events: false,
    );

    expect(settings.activeAlertCount, 1);
  });

  test('channel ids are unique and prefixed', () {
    final ids = NotificationKind.values.map((k) => k.channelId).toSet();

    expect(ids, hasLength(NotificationKind.values.length));
    expect(ids, contains('hoyo_aio_stamina'));
  });
}
