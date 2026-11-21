import SwiftUI

extension Color {
    init(argb: UInt32) {
        self.init(
            .sRGB,
            red: Double((argb >> 16) & 0xFF) / 255,
            green: Double((argb >> 8) & 0xFF) / 255,
            blue: Double(argb & 0xFF) / 255,
            opacity: Double((argb >> 24) & 0xFF) / 255
        )
    }
}

struct WidgetPalette {
    let background: Color
    let border: Color
    let text: Color
    let text2: Color
    let track: Color
}

enum WidgetTokens {
    static let radius: CGFloat = 22
    static let lime = Color(argb: 0xFFD2E843)
    static let ink = Color(argb: 0xFF1B1D16)
    static let accents: [String: Color] = [
        "genshin": Color(argb: 0xFF4A90E2),
        "starRail": Color(argb: 0xFF8B7CF6),
        "zzz": Color(argb: 0xFFF5C518),
        "hi3": Color(argb: 0xFFE94B6A),
    ]
    ]
    static let light = WidgetPalette(
        background: Color(argb: 0xF0FFFFFF),
        border: Color(argb: 0x140F1115),
        text: Color(argb: 0xFF14161B),
        text2: Color(argb: 0xFF4A5060),
        track: Color(argb: 0xFFE6E9EE)
    )
    static let dark = WidgetPalette(
        background: Color(argb: 0xF0171A21),
        border: Color(argb: 0x14FFFFFF),
        text: Color(argb: 0xFFF2F3F5),
        text2: Color(argb: 0xFFB6BCC8),
        track: Color(argb: 0xFF262B35)
    )
    static let clear = WidgetPalette(
        background: Color(argb: 0x47080A0E),
        border: Color(argb: 0x3DFFFFFF),
        text: Color(argb: 0xFFFFFFFF),
        text2: Color(argb: 0xCCFFFFFF),
        track: Color(argb: 0x3DFFFFFF)
    )
    static let palettes: [String: WidgetPalette] = [
        "light": light,
        "dark": dark,
        "clear": clear,
    ]
}
