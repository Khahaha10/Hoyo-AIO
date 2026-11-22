import 'package:material_ui/material_ui.dart';

const _unknownElement = Color(0xFFB8BEC8);

const _elementColors = <String, Color>{
  'pyro': Color(0xFFEF7B5A),
  'hydro': Color(0xFF5BB5F5),
  'anemo': Color(0xFF74D3AE),
  'electro': Color(0xFFB07CE8),
  'dendro': Color(0xFFA5C83B),
  'cryo': Color(0xFF9BDDF5),
  'geo': Color(0xFFF0B83E),
  'physical': Color(0xFFB8BEC8),
  'fire': Color(0xFFEF7B5A),
  'ice': Color(0xFF9BDDF5),
  'lightning': Color(0xFFB07CE8),
  'electric': Color(0xFF5BB5F5),
  'wind': Color(0xFF74D3AE),
  'quantum': Color(0xFF7C80E8),
  'imaginary': Color(0xFFF2D14D),
  'ether': Color(0xFFE880B8),
};

Color chronicleElementColor(String? element) =>
    _elementColors[element] ?? _unknownElement;
