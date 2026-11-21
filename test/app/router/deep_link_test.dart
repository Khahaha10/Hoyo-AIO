import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/app/router/deep_link.dart';

String _to(String link) => DeepLink.toLocation(Uri.parse(link));

void main() {
  group('DeepLink', () {
    test('recognizes only the hoyoaio scheme', () {
      expect(DeepLink.isDeepLink(Uri.parse('hoyoaio://dashboard')), isTrue);
      expect(DeepLink.isDeepLink(Uri.parse('https://dashboard')), isFalse);
      expect(DeepLink.isDeepLink(Uri.parse('/dashboard')), isFalse);
    });

    test('keeps a dashboard game and a numeric role', () {
      expect(
        _to('hoyoaio://dashboard?game=genshin&role=800000001'),
        '/dashboard?game=genshin&role=800000001',
      );
      expect(
        _to('hoyoaio://dashboard?game=starRail'),
        '/dashboard?game=starRail',
      );
      expect(
        _to('hoyoaio://dashboard?role=800000001'),
        '/dashboard?role=800000001',
      );
    });

    test('drops HI3, unknown games and invalid roles', () {
      expect(_to('hoyoaio://dashboard?game=hi3'), AppRoutes.dashboard);
      expect(_to('hoyoaio://dashboard?game=pokemon'), AppRoutes.dashboard);
      expect(_to('hoyoaio://dashboard?role=abc'), AppRoutes.dashboard);
      expect(
        _to('hoyoaio://dashboard?role=1234567890123'),
        AppRoutes.dashboard,
      );
      expect(
        _to('hoyoaio://dashboard?game=zzz&role=1;drop'),
        '/dashboard?game=zzz',
      );
    });

    test('other hosts and schemes fall back to the dashboard', () {
      expect(_to('hoyoaio://settings?game=zzz'), AppRoutes.dashboard);
      expect(_to('https://dashboard?game=zzz'), AppRoutes.dashboard);
      expect(_to('hoyoaio://dashboard'), AppRoutes.dashboard);
    });
  });

  group('AppRoutes builders', () {
    test('build tracker and widget editor locations', () {
      expect(AppRoutes.trackerFor(DeepLinkTestGame.zzz), '/tracker?game=zzz');
      expect(
        AppRoutes.trackerHistory(DeepLinkTestGame.zzz, '2'),
        '/tracker/history?game=zzz&banner=2',
      );
      expect(
        AppRoutes.widgetEditor(4, DeepLinkTestGame.zzz),
        '/widgets/edit?id=4&size=zzz',
      );
      expect(AppRoutes.events, '/codes?tab=events');
    });
  });
}

enum DeepLinkTestGame { zzz }
