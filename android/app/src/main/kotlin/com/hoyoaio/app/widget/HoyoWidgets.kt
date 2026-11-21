package com.hoyoaio.app.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.content.Intent
import android.content.res.Configuration
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.action.ActionParameters
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.LinearProgressIndicator
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.hoyoaio.app.MainActivity
import com.hoyoaio.app.R
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import java.text.NumberFormat
import java.time.Instant

enum class WidgetSize { SMALL, MEDIUM, LARGE }

data class WidgetStyle(
    val palette: WidgetPalette,
    val accent: Color?,
    val scale: Float,
    val background: Color,
)

abstract class HoyoWidget(private val widgetSize: WidgetSize) : GlanceAppWidget() {
    override val stateDefinition: GlanceStateDefinition<*> = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val widgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)
        provideContent {
            val state = currentState<HomeWidgetGlanceState>()
            val snapshot = WidgetSnapshot.read(state.preferences)
            WidgetFrame(snapshot, snapshot?.config(widgetId), widgetSize)
        }
    }
}

class SmallWidget : HoyoWidget(WidgetSize.SMALL)

class MediumWidget : HoyoWidget(WidgetSize.MEDIUM)

class LargeWidget : HoyoWidget(WidgetSize.LARGE)

class SmallWidgetReceiver : HomeWidgetGlanceWidgetReceiver<SmallWidget>() {
    override val glanceAppWidget = SmallWidget()
}

class MediumWidgetReceiver : HomeWidgetGlanceWidgetReceiver<MediumWidget>() {
    override val glanceAppWidget = MediumWidget()
}

class LargeWidgetReceiver : HomeWidgetGlanceWidgetReceiver<LargeWidget>() {
    override val glanceAppWidget = LargeWidget()
}

class RefreshAction : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        val flavor = if (context.packageName.endsWith(".dev")) "dev" else "prod"
        HomeWidgetBackgroundIntent
            .getBroadcast(context, Uri.parse("hoyoaio://refresh?flavor=$flavor"))
            .send()
    }
}

private const val SCALE_SMALL = 0.9f
private const val SCALE_LARGE = 1.15f
private const val MAX_ITEMS = 3
private const val MAX_LARGE_ROLES = 3
private const val PADDING_DP = 16
private const val SMALL_RING_DP = 44
private const val MEDIUM_RING_DP = 52
private const val RING_STROKE_DP = 7f
private const val LABEL_WIDTH_DP = 64
private const val BAR_HEIGHT_DP = 6
private const val FULL_CIRCLE = 360f
private const val START_ANGLE = -90f

private fun styleFor(context: Context, config: WidgetConfig?, game: String?): WidgetStyle {
    val night = context.resources.configuration.uiMode and
        Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
    val themeKey = when (val theme = config?.theme ?: "system") {
        "light", "dark", "clear" -> theme
        else -> if (night) "dark" else "light"
    }
    val palette = WidgetTokens.palettes.getValue(themeKey)
    val accent = when (val accent = config?.accent ?: "match") {
        "match" -> game?.let { WidgetTokens.accents[it] }
        "lime" -> WidgetTokens.lime
        "neutral" -> palette.text2
        else -> WidgetTokens.accents[accent]
    }
    val scale = when (config?.fontSize) {
        "small" -> SCALE_SMALL
        "large" -> SCALE_LARGE
        else -> 1f
    }
    val background = config?.let {
        palette.background.copy(alpha = palette.background.alpha * it.opacity)
    } ?: palette.background
    return WidgetStyle(palette, accent, scale, background)
}

private fun dashboardAction(context: Context, role: WidgetRole?) = actionStartActivity(
    Intent(context, MainActivity::class.java)
        .setAction(Intent.ACTION_VIEW)
        .setData(
            Uri.parse(
                if (role == null) "hoyoaio://dashboard"
                else "hoyoaio://dashboard?game=${role.game}&role=${role.uid}",
            ),
        ),
)

@Composable
private fun WidgetFrame(snapshot: WidgetSnapshot?, config: WidgetConfig?, size: WidgetSize) {
    val context = LocalContext.current
    val role = snapshot?.role(config?.roleId)
    val style = styleFor(context, config, role?.game)
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .cornerRadius(WidgetTokens.RADIUS_DP.dp)
            .background(style.background)
            .padding(PADDING_DP.dp)
            .clickable(dashboardAction(context, role)),
    ) {
        when {
            snapshot == null || role == null -> Label(
                context.getString(R.string.widget_empty),
                style.palette.text2,
                (12 * style.scale).sp,
            )
            size == WidgetSize.SMALL -> SmallContent(snapshot, role, style)
            size == WidgetSize.MEDIUM -> MediumContent(snapshot, role, config, style)
            else -> LargeContent(snapshot, style)
        }
    }
}

@Composable
private fun SmallContent(snapshot: WidgetSnapshot, role: WidgetRole, style: WidgetStyle) {
    val now = Instant.now()
    val accent = style.accentFor(role.game)
    Row(verticalAlignment = Alignment.CenterVertically, modifier = GlanceModifier.fillMaxSize()) {
        Ring(role, now, accent, style, SMALL_RING_DP)
        Spacer(GlanceModifier.width(12.dp))
        Column {
            Row(verticalAlignment = Alignment.Bottom) {
                Label(role.stamina.currentAt(now).toString(), style.palette.text, (20 * style.scale).sp, bold = true)
                Label("/${role.stamina.max}", style.palette.text2, (12 * style.scale).sp)
            }
            Label(fullText(snapshot, role, now), style.palette.text2, (12 * style.scale).sp)
        }
    }
}

@Composable
private fun MediumContent(
    snapshot: WidgetSnapshot,
    role: WidgetRole,
    config: WidgetConfig?,
    style: WidgetStyle,
) {
    val now = Instant.now()
    val accent = style.accentFor(role.game)
    val visible = config?.visibleItems?.takeIf { it.isNotEmpty() }
    val items = (visible?.mapNotNull { key -> role.items.firstOrNull { it.key == key } }
        ?: role.items).take(MAX_ITEMS)
    val small = (12 * style.scale).sp
    Column(modifier = GlanceModifier.fillMaxSize()) {
        Row(verticalAlignment = Alignment.CenterVertically, modifier = GlanceModifier.fillMaxWidth()) {
            Dot(accent)
            Spacer(GlanceModifier.width(6.dp))
            Box(modifier = GlanceModifier.defaultWeight()) {
                Label(snapshot.label("game.${role.game}"), style.palette.text, (13 * style.scale).sp, bold = true)
            }
            Box(modifier = GlanceModifier.clickable(actionRunCallback<RefreshAction>())) {
                Label(WidgetSnapshot.clockTime(role.fetchedAt), style.palette.text2, small)
            }
        }
        Spacer(GlanceModifier.defaultWeight())
        Row(verticalAlignment = Alignment.CenterVertically) {
            Ring(role, now, accent, style, MEDIUM_RING_DP)
            Spacer(GlanceModifier.width(10.dp))
            Column {
                Label(role.stamina.currentAt(now).toString(), style.palette.text, (24 * style.scale).sp, bold = true)
                Label(fullText(snapshot, role, now), style.palette.text2, small)
            }
        }
        Spacer(GlanceModifier.defaultWeight())
        items.forEach { item ->
            Row(modifier = GlanceModifier.fillMaxWidth()) {
                Box(modifier = GlanceModifier.defaultWeight()) {
                    Label(snapshot.label(item.key), style.palette.text2, small)
                }
                Label(itemValue(snapshot, item, now), style.palette.text, small, bold = true)
            }
        }
    }
}

@Composable
private fun LargeContent(snapshot: WidgetSnapshot, style: WidgetStyle) {
    val now = Instant.now()
    val small = (12 * style.scale).sp
    val latest = snapshot.roles.maxOfOrNull { it.fetchedAt }
    Column(modifier = GlanceModifier.fillMaxSize()) {
        Row(verticalAlignment = Alignment.CenterVertically, modifier = GlanceModifier.fillMaxWidth()) {
            Box(modifier = GlanceModifier.defaultWeight()) {
                Label(snapshot.label("app"), style.palette.text, (13 * style.scale).sp, bold = true)
            }
            if (latest != null) {
                Box(modifier = GlanceModifier.clickable(actionRunCallback<RefreshAction>())) {
                    Label(
                        snapshot.label("updated").replace("{time}", WidgetSnapshot.clockTime(latest)),
                        style.palette.text2,
                        small,
                    )
                }
            }
        }
        Spacer(GlanceModifier.height(8.dp))
        snapshot.roles.take(MAX_LARGE_ROLES).forEach { role ->
            val accent = style.accentFor(role.game)
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = GlanceModifier.fillMaxWidth().padding(vertical = 3.dp),
            ) {
                Dot(accent)
                Spacer(GlanceModifier.width(8.dp))
                Box(modifier = GlanceModifier.width(LABEL_WIDTH_DP.dp)) {
                    Label(snapshot.label("short.${role.stamina.key}"), style.palette.text, small, bold = true)
                }
                LinearProgressIndicator(
                    progress = role.stamina.progressAt(now),
                    modifier = GlanceModifier.defaultWeight().height(BAR_HEIGHT_DP.dp),
                    color = ColorProvider(accent),
                    backgroundColor = ColorProvider(style.palette.track),
                )
                Spacer(GlanceModifier.width(8.dp))
                Label("${role.stamina.currentAt(now)}/${role.stamina.max}", style.palette.text, small, bold = true)
            }
        }
        Spacer(GlanceModifier.defaultWeight())
        if (snapshot.checkInTotal > 0) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Image(
                    provider = ImageProvider(R.drawable.ic_widget_check),
                    contentDescription = null,
                    colorFilter = ColorFilter.tint(ColorProvider(style.palette.success)),
                    modifier = GlanceModifier.size(14.dp),
                )
                Spacer(GlanceModifier.width(6.dp))
                Label(
                    snapshot.label("checkedIn")
                        .replace("{done}", snapshot.checkInDone.toString())
                        .replace("{total}", snapshot.checkInTotal.toString()),
                    style.palette.success,
                    small,
                    bold = true,
                )
            }
        }
    }
}

@Composable
private fun Ring(role: WidgetRole, now: Instant, accent: Color, style: WidgetStyle, sizeDp: Int) {
    val context = LocalContext.current
    Image(
        provider = ImageProvider(
            ringBitmap(context, sizeDp, role.stamina.progressAt(now), accent, style.palette.track),
        ),
        contentDescription = null,
        modifier = GlanceModifier.size(sizeDp.dp),
    )
}

private fun ringBitmap(context: Context, sizeDp: Int, progress: Float, color: Color, track: Color): Bitmap {
    val density = context.resources.displayMetrics.density
    val px = (sizeDp * density).toInt().coerceAtLeast(1)
    val stroke = RING_STROKE_DP * density
    val bitmap = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = stroke
        strokeCap = Paint.Cap.ROUND
    }
    val rect = RectF(stroke / 2, stroke / 2, px - stroke / 2, px - stroke / 2)
    paint.color = track.toArgb()
    canvas.drawArc(rect, 0f, FULL_CIRCLE, false, paint)
    paint.color = color.toArgb()
    canvas.drawArc(rect, START_ANGLE, FULL_CIRCLE * progress.coerceIn(0f, 1f), false, paint)
    return bitmap
}

@Composable
private fun Dot(color: Color, size: Dp = 8.dp) {
    Box(modifier = GlanceModifier.size(size).cornerRadius(size / 2).background(color)) {}
}

@Composable
private fun Label(text: String, color: Color, size: TextUnit, bold: Boolean = false) {
    Text(
        text = text,
        maxLines = 1,
        style = TextStyle(
            color = ColorProvider(color),
            fontSize = size,
            fontWeight = if (bold) FontWeight.Bold else FontWeight.Medium,
        ),
    )
}

private fun WidgetStyle.accentFor(game: String): Color =
    accent ?: WidgetTokens.accents[game] ?: WidgetTokens.lime

private fun WidgetStamina.progressAt(now: Instant): Float =
    if (max <= 0) 0f else currentAt(now).toFloat() / max

private fun fullText(snapshot: WidgetSnapshot, role: WidgetRole, now: Instant): String =
    if (role.stamina.isFullAt(now)) snapshot.label("full")
    else "${snapshot.label("full")} ${WidgetSnapshot.clockTime(role.stamina.fullAt)}"

private fun itemValue(snapshot: WidgetSnapshot, item: WidgetItem, now: Instant): String {
    val state = item.state
    val doneAt = item.doneAt
    val max = item.max ?: 0
    val allBack = doneAt != null && !now.isBefore(doneAt)
    return when {
        item.key == "videoStore" && state != null -> snapshot.label("videoStore.$state")
        item.key == "scratchCard" -> if (state == "done") snapshot.label("done") else "0/1"
        item.key == "realm" -> NumberFormat.getIntegerInstance().format(item.value ?: 0)
        item.key == "transformer" && (doneAt == null || allBack) -> snapshot.label("ready")
        item.key == "transformer" && doneAt != null -> WidgetSnapshot.clockTime(doneAt)
        item.key == "expeditions" || item.key == "assignments" ->
            "${if (allBack) max else item.value ?: 0}/$max"
        else -> "${item.value ?: 0}/$max"
    }
}
