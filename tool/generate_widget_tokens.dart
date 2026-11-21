import 'dart:convert';
import 'dart:io';

import 'package:hoyo_aio/core/design_system/tokens/widget_tokens.dart';

const _kotlinPath =
    'android/app/src/main/kotlin/com/hoyoaio/app/widget/WidgetTokens.kt';

void main() {
  const encoder = JsonEncoder.withIndent('  ');
  File(
    'tool/widget_tokens.json',
  ).writeAsStringSync('${encoder.convert(WidgetTokens.toJson())}\n');
  File(_kotlinPath).writeAsStringSync(_kotlin());
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
      ..writeln('        ),');
  }
  buffer
    ..writeln('    )')
    ..writeln('}');
  return buffer.toString();
}
