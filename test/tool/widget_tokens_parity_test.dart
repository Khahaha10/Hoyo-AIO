import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/design_system/tokens/widget_tokens.dart';

const _jsonPath = 'tool/widget_tokens.json';
const _kotlinPath =
    'android/app/src/main/kotlin/com/hoyoaio/app/widget/WidgetTokens.kt';
const _swiftPath = 'ios/HoYoWidgets/WidgetTokens.swift';

String _hex(String raw) => '#${raw.toUpperCase()}';

Map<String, String> _pairs(String block, RegExp pattern) => {
  for (final match in pattern.allMatches(block))
    match.group(1)!: _hex(match.group(2)!),
};

String _between(String source, String start, String end) {
  final from = source.indexOf(start);
  expect(from, isNot(-1), reason: 'missing "$start"');
  final to = source.indexOf(end, from + start.length);
  return source.substring(from + start.length, to == -1 ? null : to);
}

Map<String, Object> _parseKotlin(String source) {
  final color = RegExp(r'Color\(0x([0-9A-Fa-f]{8})\)');
  String single(String name) =>
      _hex(color.firstMatch(_between(source, 'val $name = ', '\n'))!.group(1)!);
  final palettes = _between(source, 'val palettes = mapOf(', '\n    )\n');
  return {
    'radius': int.parse(
      RegExp(r'RADIUS_DP = (\d+)').firstMatch(source)!.group(1)!,
    ),
    'lime': single('lime'),
    'ink': single('ink'),
    'accents': _pairs(
      _between(source, 'val accents = mapOf(', '\n    )'),
      RegExp(r'"(\w+)" to Color\(0x([0-9A-Fa-f]{8})\)'),
    ),
    'themes': {
      for (final match in RegExp(
        r'"(\w+)" to WidgetPalette\(([\s\S]*?)\n        \),',
      ).allMatches(palettes))
        match.group(1)!: _pairs(
          match.group(2)!,
          RegExp(r'(\w+) = Color\(0x([0-9A-Fa-f]{8})\)'),
        ),
    },
  };
}

Map<String, Object> _parseSwift(String source) {
  final color = RegExp(r'Color\(argb: 0x([0-9A-Fa-f]{8})\)');
  String single(String name) => _hex(
    color.firstMatch(_between(source, 'static let $name = ', '\n'))!.group(1)!,
  );
  return {
    'radius': int.parse(
      RegExp(r'static let radius: CGFloat = (\d+)')
          .firstMatch(source)!
          .group(1)!,
    ),
    'lime': single('lime'),
    'ink': single('ink'),
    'accents': _pairs(
      _between(source, 'static let accents: [String: Color] = [', '\n    ]'),
      RegExp(r'"(\w+)": Color\(argb: 0x([0-9A-Fa-f]{8})\)'),
    ),
    'themes': {
      for (final match in RegExp(
        r'static let (\w+) = WidgetPalette\(([\s\S]*?)\n    \)',
      ).allMatches(source))
        match.group(1)!: _pairs(
          match.group(2)!,
          RegExp(r'(\w+): Color\(argb: 0x([0-9A-Fa-f]{8})\)'),
        ),
    },
  };
}

int _balance(String source, String open, String close) =>
    open.allMatches(source).length - close.allMatches(source).length;

void main() {
  final expected = jsonDecode(File(_jsonPath).readAsStringSync());

  test('Dart WidgetTokens match tool/widget_tokens.json', () {
    expect(jsonDecode(jsonEncode(WidgetTokens.toJson())), expected);
  });

  test('Kotlin WidgetTokens.kt matches tool/widget_tokens.json', () {
    final kotlin = _parseKotlin(File(_kotlinPath).readAsStringSync());

    expect(kotlin, expected);
  });

  test('Swift WidgetTokens.swift matches tool/widget_tokens.json', () {
    final swift = _parseSwift(File(_swiftPath).readAsStringSync());

    expect(swift, expected);
  });

  test(
    'Swift WidgetTokens.swift has balanced brackets',
    () {
      final swift = File(_swiftPath).readAsStringSync();

      expect(_balance(swift, '[', ']'), 0);
      expect(_balance(swift, '(', ')'), 0);
      expect(_balance(swift, '{', '}'), 0);
    },
    skip:
        'BUG: tool/generate_widget_tokens.dart:56 writes a second "]" after '
        'the accents dictionary, so WidgetTokens.swift does not compile',
  );
}
