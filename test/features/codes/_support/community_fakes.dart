import 'dart:async';

import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/codes/domain/codes_repository.dart';
import 'package:hoyo_aio/features/codes/domain/redeem_code.dart';
import 'package:hoyo_aio/features/events/domain/events_repository.dart';
import 'package:hoyo_aio/features/events/domain/web_event.dart';

import '../../tracker/_support/tracker_support.dart';

RedeemCode redeemCode(
  String code, {
  Game game = Game.genshin,
  bool active = true,
  bool unread = false,
  DateTime? expiresAt,
  DateTime? redeemedAt,
  List<int> rewards = const [60],
}) => RedeemCode(
  game: game,
  code: code,
  rewards: rewards,
  active: active,
  firstSeenAt: testNow.subtract(const Duration(hours: 2)),
  unread: unread,
  expiresAt: expiresAt,
  redeemedAt: redeemedAt,
);

WebEvent webEvent(
  String id, {
  Game game = Game.genshin,
  Duration startOffset = const Duration(days: -1),
  Duration endOffset = const Duration(days: 3),
  bool remind = false,
  bool unread = false,
  String summary = 'Summary text',
}) => WebEvent(
  id: id,
  game: game,
  name: 'Event $id',
  summary: summary,
  startAt: testNow.add(startOffset),
  endAt: testNow.add(endOffset),
  webPath: '/article/$id',
  active: true,
  remind: remind,
  unread: unread,
  firstSeenAt: testNow,
);

class FakeCodesRepository implements CodesRepository {
  FakeCodesRepository(this.codes);

  List<RedeemCode> codes;
  final _changes = StreamController<void>.broadcast();
  Object? refreshError;
  var refreshCalls = 0;
  var markAllReadCalls = 0;
  final redeemed = <String>[];

  @override
  Future<List<RedeemCode>> refresh() async {
    refreshCalls++;
    if (refreshError case final error?) throw error;
    return const [];
  }

  @override
  Stream<List<RedeemCode>> watch() async* {
    yield codes;
    await for (final _ in _changes.stream) {
      yield codes;
    }
  }

  @override
  Future<void> markAllRead() async => markAllReadCalls++;

  @override
  Future<void> markRedeemed(Game game, String code) async {
    redeemed.add(code);
    codes = [
      for (final item in codes)
        item.code == code ? item.copyWith(redeemedAt: testNow) : item,
    ];
    _changes.add(null);
  }
}

class FakeEventsRepository implements EventsRepository {
  FakeEventsRepository(this.events);

  List<WebEvent> events;
  final reminders = <String, bool>{};
  var markAllReadCalls = 0;

  @override
  Future<List<WebEvent>> refresh() async => const [];

  @override
  Stream<List<WebEvent>> watch() => Stream.value(events);

  @override
  Future<void> markAllRead() async => markAllReadCalls++;

  @override
  Future<void> setRemind(String id, {required bool remind}) async =>
      reminders[id] = remind;

  @override
  Future<List<WebEvent>> takeEndingSoon(Duration within) async => const [];
}
