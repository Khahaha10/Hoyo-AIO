import 'package:hoyo_aio/features/events/domain/web_event.dart';

abstract interface class EventsRepository {
  Future<List<WebEvent>> refresh();

  Stream<List<WebEvent>> watch();

  Future<void> markAllRead();

  Future<void> setRemind(String id, {required bool remind});

  Future<List<WebEvent>> takeEndingSoon(Duration within);
}
