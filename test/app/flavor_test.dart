import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/flavor.dart';

void main() {
  group('Flavor', () {
    test('dev enables verbose logging and the component gallery', () {
      expect(Flavor.dev.verboseLogging, isTrue);
      expect(Flavor.dev.galleryEnabled, isTrue);
    });

    test('prod disables verbose logging and the component gallery', () {
      expect(Flavor.prod.verboseLogging, isFalse);
      expect(Flavor.prod.galleryEnabled, isFalse);
    });

    test('app titles match the Android launcher labels', () {
      expect(Flavor.dev.appTitle, 'HoYo Dev');
      expect(Flavor.prod.appTitle, 'HoYo AIO');
    });
  });
}
