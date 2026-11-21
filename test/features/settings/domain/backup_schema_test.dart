import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/features/settings/domain/backup_schema.dart';

import '../_support/settings_support.dart';

Map<String, Object?> _json() =>
    jsonDecode(sampleBackup().encode()) as Map<String, Object?>;

Matcher _rejects(String reason) => throwsA(
  isA<BackupFormatException>().having((e) => e.reason, 'reason', reason),
);

void main() {
  test('encode and decode round trip keeps every field', () {
    final original = sampleBackup();

    final decoded = BackupData.decode(original.encode());

    expect(decoded.encode(), original.encode());
    expect(decoded.exportedAt, original.exportedAt.toUtc());
    expect(decoded.settings.themeMode, AppThemeMode.dark);
    expect(decoded.settings.localeCode, 'id');
    expect(decoded.settings.autoCheckInGames, [Game.genshin, Game.zzz]);
    expect(decoded.accounts.single.roles.single.uid, fakeUid);
    expect(decoded.widgets.single.roleGame, Game.genshin);
    expect(decoded.widgets.single.opacity, 0.5);
    expect(decoded.widgets.single.visibleItems, ['resin', 'realm']);
  });

  test('a widget without account or role round trips with nulls', () {
    final json = _json();
    final widget = (json['widgets']! as List<Object?>).single! as Map;
    widget
      ..['accountId'] = null
      ..['roleGame'] = null
      ..['roleUid'] = null;

    final decoded = BackupData.decode(jsonEncode(json));

    expect(decoded.widgets.single.accountId, isNull);
    expect(decoded.widgets.single.roleGame, isNull);
  });

  test('text that is not JSON is rejected', () {
    expect(() => BackupData.decode('{not json'), _rejects('json'));
  });

  test('a JSON file from another app is rejected', () {
    final json = _json()..['app'] = 'other_app';

    expect(() => BackupData.decode(jsonEncode(json)), _rejects('notBackup'));
  });

  test('a newer backup version is rejected', () {
    final json = _json()..['version'] = BackupData.version + 1;

    expect(() => BackupData.decode(jsonEncode(json)), _rejects('newerVersion'));
  });

  test('an older unknown version is not a backup', () {
    final json = _json()..['version'] = 0;

    expect(() => BackupData.decode(jsonEncode(json)), _rejects('notBackup'));
  });

  test('an unknown enum value is rejected', () {
    final json = _json();
    (json['settings']! as Map)['themeMode'] = 'purple';

    expect(
      () => BackupData.decode(jsonEncode(json)),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('an unknown game in a role is rejected', () {
    final json = _json();
    final account = (json['accounts']! as List<Object?>).single! as Map;
    ((account['roles']! as List<Object?>).single! as Map)['game'] = 'hsr2';

    expect(
      () => BackupData.decode(jsonEncode(json)),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('widget opacity above 1 is rejected', () {
    final json = _json();
    ((json['widgets']! as List<Object?>).single! as Map)['opacity'] = 1.5;

    expect(() => BackupData.decode(jsonEncode(json)), _rejects('widget'));
  });

  test('a non-string visible item is rejected', () {
    final json = _json();
    ((json['widgets']! as List<Object?>).single! as Map)['visibleItems'] = [1];

    expect(() => BackupData.decode(jsonEncode(json)), _rejects('item'));
  });

  for (final minutes in [-1, Duration.minutesPerDay]) {
    test('auto check-in minutes $minutes are rejected', () {
      final json = _json();
      (json['settings']! as Map)['autoCheckInMinutes'] = minutes;

      expect(() => BackupData.decode(jsonEncode(json)), _rejects('settings'));
    });
  }

  test('a refresh interval below the minimum is rejected', () {
    final json = _json();
    (json['settings']! as Map)['refreshIntervalMinutes'] = 5;

    expect(() => BackupData.decode(jsonEncode(json)), _rejects('settings'));
  });

  test('an empty account id is rejected', () {
    final json = _json();
    ((json['accounts']! as List<Object?>).single! as Map)['id'] = '';

    expect(() => BackupData.decode(jsonEncode(json)), _rejects('account'));
  });

  test('an empty role uid is rejected', () {
    final json = _json();
    final account = (json['accounts']! as List<Object?>).single! as Map;
    ((account['roles']! as List<Object?>).single! as Map)['uid'] = '';

    expect(() => BackupData.decode(jsonEncode(json)), _rejects('role'));
  });

  test('an unreadable export date is rejected', () {
    final json = _json()..['exportedAt'] = 'yesterday';

    expect(() => BackupData.decode(jsonEncode(json)), _rejects('exportedAt'));
  });

  test('text larger than 1 MB is rejected before parsing', () {
    final text = ' ' * (BackupData.maxBytes + 1);

    expect(() => BackupData.decode(text), _rejects('size'));
  });

  test('the exception names its reason', () {
    expect(
      const BackupFormatException('json').toString(),
      'BackupFormatException: json',
    );
  });
}
