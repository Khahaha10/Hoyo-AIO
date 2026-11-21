import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/network/lenient_int.dart';

void main() {
  const converter = LenientInt();

  test('reads ints, doubles and numeric strings', () {
    expect(converter.fromJson(5), 5);
    expect(converter.fromJson(5.9), 5);
    expect(converter.fromJson(' 42 '), 42);
  });

  test('falls back to 0 for anything else', () {
    expect(converter.fromJson('abc'), 0);
    expect(converter.fromJson(null), 0);
    expect(converter.fromJson(const <int>[]), 0);
  });

  test('writes the int unchanged', () {
    expect(converter.toJson(7), 7);
  });
}
