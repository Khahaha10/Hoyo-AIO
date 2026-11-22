import 'dart:convert';
import 'dart:io';

import 'package:hoyo_aio/core/design_system/tokens/widget_tokens.dart';

const _kotlinPath =
    'android/app/src/main/kotlin/com/hoyoaio/app/widget/WidgetTokens.kt';
const _swiftPath = 'ios/HoYoWidgets/WidgetTokens.swift';

void main() {
  const encoder = JsonEncoder.withIndent('  ');
  File('tool/widget_tokens.json')
      .writeAsStringSync('${encoder.convert(WidgetTokens.toJson())}\n');
  File(_kotlinPath).writeAsStringSync(_kotlin());
  File(_swiftPath).writeAsStringSync(_swift());
}

String _swiftColor(int argb) =>
    'Color(argb: 0x${argb.toRadixString(16).padLeft(8, '0').toUpperCase()})';

String _swift() {
  final buffer = StringBuffer()
    ..writeln('import SwiftUI')
    ..writeln()
    ..writeln('extension Color {')
    ..writeln('    init(argb: UInt32) {')
    ..writeln('        self.init(')
    ..writeln('            .sRGB,')
    ..writeln('            red: Double((argb >> 16) & 0xFF) / 255,')
    ..writeln('            green: Double((argb >> 8) & 0xFF) / 255,')
    ..writeln('            blue: Double(argb & 0xFF) / 255,')
    ..writeln('            opacity: Double((argb >> 24) & 0xFF) / 255')
    ..writeln('        )')
    ..writeln('    }')
    ..writeln('}')
    ..writeln()
    ..writeln('struct WidgetPalette {')
    ..writeln('    let background: Color')
    ..writeln('    let border: Color')
    ..writeln('    let text: Color')
    ..writeln('    let text2: Color')
    ..writeln('    let track: Color')
    ..writeln('    let success: Color')
    ..writeln('}')
    ..writeln()
    ..writeln('enum WidgetTokens {')
    ..writeln('    static let radius: CGFloat = ${WidgetTokens.radius}')
    ..writeln('    static let lime = ${_swiftColor(WidgetTokens.lime)}')
    ..writeln('    static let ink = ${_swiftColor(WidgetTokens.ink)}')
    ..writeln('    static let accents: [String: Color] = [');
  for (final MapEntry(:key, :value) in WidgetTokens.accents.entries) {
    buffer.writeln('        "$key": ${_swiftColor(value)},');
  }
  buffer.writeln('    ]');
  for (final MapEntry(:key, :value) in WidgetTokens.themes.entries) {
    buffer
      ..writeln('    static let $key = WidgetPalette(')
      ..writeln('        background: ${_swiftColor(value['background']!)},')
      ..writeln('        border: ${_swiftColor(value['border']!)},')
      ..writeln('        text: ${_swiftColor(value['text']!)},')
      ..writeln('        text2: ${_swiftColor(value['text2']!)},')
      ..writeln('        track: ${_swiftColor(value['track']!)},')
      ..writeln('        success: ${_swiftColor(value['success']!)}')
      ..writeln('    )');
  }
  buffer.writeln('    static let palettes: [String: WidgetPalette] = [');
  for (final key in WidgetTokens.themes.keys) {
    buffer.writeln('        "$key": $key,');
  }
  buffer
    ..writeln('    ]')
    ..writeln('}');
  return buffer.toString();
}

String _color(int argb) =>
    'Color(0x${argb.toRadixString(16).padLeft(8, '0').toUpperCase()})';

String _kotlin() {
  final buffer = StringBuffer()
    ..writeln('package com.hoyoaio.app.widget')
    ..writeln()
    ..writeln('import androidx.compose.ui.graphics.Color')
    ..writeln()
    ..writeln('data class WidgetPalette(')
    ..writeln('    val background: Color,')
    ..writeln('    val border: Color,')
    ..writeln('    val text: Color,')
    ..writeln('    val text2: Color,')
    ..writeln('    val track: Color,')
    ..writeln('    val success: Color,')
    ..writeln(')')
    ..writeln()
    ..writeln('object WidgetTokens {')
    ..writeln('    const val RADIUS_DP = ${WidgetTokens.radius}')
    ..writeln('    val lime = ${_color(WidgetTokens.lime)}')
    ..writeln('    val ink = ${_color(WidgetTokens.ink)}')
    ..writeln('    val accents = mapOf(');
  for (final MapEntry(:key, :value) in WidgetTokens.accents.entries) {
    buffer.writeln('        "$key" to ${_color(value)},');
  }
  buffer
    ..writeln('    )')
    ..writeln('    val palettes = mapOf(');
  for (final MapEntry(:key, :value) in WidgetTokens.themes.entries) {
    buffer
      ..writeln('        "$key" to WidgetPalette(')
      ..writeln('            background = ${_color(value['background']!)},')
      ..writeln('            border = ${_color(value['border']!)},')
      ..writeln('            text = ${_color(value['text']!)},')
      ..writeln('            text2 = ${_color(value['text2']!)},')
      ..writeln('            track = ${_color(value['track']!)},')
      ..writeln('            success = ${_color(value['success']!)},')
      ..writeln('        ),');
  }
  buffer
    ..writeln('    )')
    ..writeln('}');
  return buffer.toString();
}
