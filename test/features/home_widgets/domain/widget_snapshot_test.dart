import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/dashboard/domain/note_result.dart';
import 'package:hoyo_aio/features/home_widgets/data/widget_labels.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot_builder.dart';
import 'package:material_ui/material_ui.dart';

import '../_support/widget_fixtures.dart';

const _maxSnapshotBytes = 16 * 1024;
final _secretKey = RegExp(
  'cookie|token|authkey|ltuid|ltmid|stoken|account_?id|mid_v2',
  caseSensitive: false,
);
const _fakeCookieParts = ['ltoken_v2', 'v2_fakeltoken', 'cookie_token'];

WidgetSnapshot _realistic() {
  final notes = <(SavedRole, NoteResult)>[
    for (var account = 0; account < 3; account++)
      for (final (index, (_, result)) in allNotes.indexed)
        (
          role(
            account * 10 + index + 1,
            result.note.game,
            accountId: '90000000$account',
          ),
          result,
        ),
  ];
  return WidgetSnapshotBuilder.build(
    notes: notes,
    checkInToday: [record(Game.genshin, CheckInResult.claimed)],
    day: '2026-11-21',
    checkInTotal: 4,
    widgets: [
      for (var id = 0; id < 6; id++)
        config(widgetId: id, visibleItems: const ['realm', 'commissions']),
    ],
    labels: widgetLabels(lookupAppLocalizations(const Locale('en'))),
    now: fetchedAt,
  );
}

Iterable<String> _keys(Object? json) sync* {
  if (json is Map) {
    for (final MapEntry(:key, :value) in json.entries) {
      yield '$key';
      yield* _keys(value);
    }
  } else if (json is List) {
    for (final item in json) {
      yield* _keys(item);
    }
  }
}

Iterable<String> _structuralKeys(Map<String, Object?> json) => _keys({
  for (final MapEntry(:key, :value) in json.entries)
    if (key != 'labels') key: value,
});

void main() {
  group('WidgetSnapshot JSON', () {
    test('round-trips through jsonEncode and fromJson', () {
      final snapshot = _realistic();

      final decoded = WidgetSnapshot.fromJson(
        jsonDecode(jsonEncode(snapshot.toJson())) as Map<String, dynamic>,
      );

      expect(decoded, snapshot);
    });

    test('serializes times as UTC ISO strings and games by name', () {
      final json =
          jsonDecode(jsonEncode(_realistic().toJson())) as Map<String, dynamic>;
      final role = (json['roles'] as List).first as Map<String, dynamic>;
      final stamina = role['stamina'] as Map<String, dynamic>;

      expect(json['generated_at'], endsWith('Z'));
      expect(stamina['full_at'], endsWith('Z'));
      expect(role['game'], 'genshin');
    });

    test('contains no secret keys anywhere in the payload structure', () {
      final json =
          jsonDecode(jsonEncode(_realistic().toJson())) as Map<String, Object?>;

      final leaked = _structuralKeys(json).where(_secretKey.hasMatch).toList();

      expect(leaked, isEmpty);
    });

    test('contains no cookie values even when the account has a cookie', () {
      final encoded = jsonEncode(_realistic().toJson());

      for (final part in _fakeCookieParts) {
        expect(encoded, isNot(contains(part)));
      }
      expect(encoded, isNot(contains(testAccountId)));
    });

    test('stays below 16 KB for nine roles and six widgets', () {
      final bytes = utf8.encode(jsonEncode(_realistic().toJson())).length;

      expect(bytes, lessThan(_maxSnapshotBytes));
    });
  });
}
