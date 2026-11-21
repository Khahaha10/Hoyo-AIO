import 'dart:convert';
import 'dart:io';

import 'package:hoyo_aio/core/design_system/tokens/widget_tokens.dart';

void main() {
  const encoder = JsonEncoder.withIndent('  ');
  File(
    'tool/widget_tokens.json',
  ).writeAsStringSync('${encoder.convert(WidgetTokens.toJson())}\n');
}
