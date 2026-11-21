import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/app/bootstrap.dart';
import 'package:hoyo_aio/app/provider_retry.dart';

void main() {
  test('registerBundledLicenses adds the reference repo and Inter', () async {
    registerBundledLicenses();

    final entries = await LicenseRegistry.licenses.toList();
    final byPackage = {
      for (final entry in entries)
        for (final package in entry.packages) package: entry,
    };

    expect(byPackage.keys, containsAll(bundledLicenses.keys));
    final reference = byPackage['android_genshin_resin_widget']!;
    final text = reference.paragraphs.map((p) => p.text).join('\n');
    expect(text, contains('MIT'));
  });

  test('providers are never retried automatically', () {
    expect(noProviderRetry(0, Exception('x')), isNull);
    expect(noProviderRetry(5, Exception('x')), isNull);
  });
}
