import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/game_region.dart';
import 'package:hoyo_aio/core/l10n/game_labels.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/l10n/resolve_l10n.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  group('GameLabels', () {
    test('every game has a distinct name, short name and level text', () {
      final names = Game.values.map(l10n.gameName).toSet();
      final short = Game.values.map(l10n.gameShortName).toSet();
      final levels = Game.values.map((g) => l10n.gameLevel(g, 60)).toList();

      expect(names, hasLength(Game.values.length));
      expect(short, hasLength(Game.values.length));
      expect(levels.every((text) => text.contains('60')), isTrue);
    });

    test('every region has a distinct name', () {
      expect(
        GameRegion.values.map(l10n.regionName).toSet(),
        hasLength(GameRegion.values.length),
      );
    });
  });

  group('groupUid', () {
    test('groups long uids in threes from the end', () {
      expect(groupUid('800000001'), '800 000 001');
      expect(groupUid('1800000001'), '1800 000 001');
    });

    test('leaves short uids alone', () {
      expect(groupUid('123456'), '123456');
      expect(groupUid(''), '');
    });
  });

  group('resolveL10n', () {
    test('returns the requested supported language', () {
      expect(resolveL10n('id').localeName, 'id');
      expect(resolveL10n('en').localeName, 'en');
    });

    test('falls back to English for an unsupported language', () {
      expect(resolveL10n('fr').localeName, 'en');
    });

    test('uses the platform language when none is set', () {
      expect(
        AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains(resolveL10n(null).localeName),
      );
    });
  });

  testWidgets('context.l10n reads the localizations', (tester) async {
    late AppLocalizations found;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en'),
        delegates: AppLocalizations.localizationsDelegates,
        child: Builder(
          builder: (context) {
            found = context.l10n;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(found.appName, l10n.appName);
  });
}
