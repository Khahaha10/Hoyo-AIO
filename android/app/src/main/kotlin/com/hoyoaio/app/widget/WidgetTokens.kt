package com.hoyoaio.app.widget

import androidx.compose.ui.graphics.Color

data class WidgetPalette(
    val background: Color,
    val border: Color,
    val text: Color,
    val text2: Color,
    val track: Color,
)

object WidgetTokens {
    const val RADIUS_DP = 22
    val lime = Color(0xFFD2E843)
    val ink = Color(0xFF1B1D16)
    val accents = mapOf(
        "genshin" to Color(0xFF4A90E2),
        "starRail" to Color(0xFF8B7CF6),
        "zzz" to Color(0xFFF5C518),
        "hi3" to Color(0xFFE94B6A),
    )
    val palettes = mapOf(
        "light" to WidgetPalette(
            background = Color(0xF0FFFFFF),
            border = Color(0x140F1115),
            text = Color(0xFF14161B),
            text2 = Color(0xFF4A5060),
            track = Color(0xFFE6E9EE),
        ),
        "dark" to WidgetPalette(
            background = Color(0xF0171A21),
            border = Color(0x14FFFFFF),
            text = Color(0xFFF2F3F5),
            text2 = Color(0xFFB6BCC8),
            track = Color(0xFF262B35),
        ),
        "clear" to WidgetPalette(
            background = Color(0x47080A0E),
            border = Color(0x3DFFFFFF),
            text = Color(0xFFFFFFFF),
            text2 = Color(0xCCFFFFFF),
            track = Color(0x3DFFFFFF),
        ),
    )
}
