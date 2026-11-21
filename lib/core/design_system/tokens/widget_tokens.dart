abstract final class WidgetTokens {
  static const int radius = 22;
  static const int lime = 0xFFD2E843;
  static const int ink = 0xFF1B1D16;

  static const Map<String, int> accents = {
    'genshin': 0xFF4A90E2,
    'starRail': 0xFF8B7CF6,
    'zzz': 0xFFF5C518,
    'hi3': 0xFFE94B6A,
  };

  static const Map<String, Map<String, int>> themes = {
    'light': {
      'background': 0xF0FFFFFF,
      'border': 0x140F1115,
      'text': 0xFF14161B,
      'text2': 0xFF4A5060,
      'track': 0xFFE6E9EE,
    },
    'dark': {
      'background': 0xF0171A21,
      'border': 0x14FFFFFF,
      'text': 0xFFF2F3F5,
      'text2': 0xFFB6BCC8,
      'track': 0xFF262B35,
    },
    'clear': {
      'background': 0x47080A0E,
      'border': 0x3DFFFFFF,
      'text': 0xFFFFFFFF,
      'text2': 0xCCFFFFFF,
      'track': 0x3DFFFFFF,
    },
  };

  static Map<String, Object> toJson() => {
    'radius': radius,
    'lime': _hex(lime),
    'ink': _hex(ink),
    'accents': {
      for (final MapEntry(:key, :value) in accents.entries) key: _hex(value),
    },
    'themes': {
      for (final MapEntry(:key, :value) in themes.entries)
        key: {
          for (final MapEntry(key: name, value: color) in value.entries)
            name: _hex(color),
        },
    },
  };

  static String _hex(int argb) =>
      '#${argb.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}
