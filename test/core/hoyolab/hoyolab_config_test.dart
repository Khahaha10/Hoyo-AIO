import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';

void main() {
  test('check-in endpoints build https URIs on allowed hosts', () {
    for (final endpoint in HoyolabConfig.checkIn.values) {
      final uris = [
        endpoint.signUri,
        endpoint.infoUri,
        endpoint.homeUri,
        endpoint.awardUri,
      ];
      for (final uri in uris) {
        expect(uri.scheme, 'https');
        expect(HoyolabConfig.allowedHosts, contains(uri.host));
        expect(uri.path, startsWith(endpoint.basePath));
      }
    }
  });

  test('every game has a check-in endpoint', () {
    expect(HoyolabConfig.checkIn.keys, containsAll(Game.values));
  });

  test('gacha hosts are allowed but separate from cookie hosts', () {
    for (final host in HoyolabConfig.gachaHosts.values) {
      expect(HoyolabConfig.allowedHosts, contains(host));
      expect(host, isNot(HoyolabConfig.gameRecordHost));
    }
  });
}
