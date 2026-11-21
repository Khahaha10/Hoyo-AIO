import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';

part 'web_event.freezed.dart';

enum EventPhase { running, upcoming, ended }

@freezed
abstract class WebEvent with _$WebEvent {
  const factory WebEvent({
    required String id,
    required Game game,
    required String name,
    required String summary,
    required DateTime startAt,
    required DateTime endAt,
    required String webPath,
    required bool active,
    required bool remind,
    required bool unread,
    required DateTime firstSeenAt,
  }) = _WebEvent;

  const WebEvent._();

  EventPhase phaseAt(DateTime now) {
    if (!endAt.isAfter(now)) return EventPhase.ended;
    if (startAt.isAfter(now)) return EventPhase.upcoming;
    return EventPhase.running;
  }
}
