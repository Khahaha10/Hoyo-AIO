package com.hoyoaio.app.widget

import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
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
            .padding(14.dp)
            .clickable(dashboardAction(context, role)),
    ) {
        when {
            snapshot == null || role == null -> Label(
                context.getString(R.string.widget_empty),
                style.palette.text2,
                13.sp,
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
    Column(modifier = GlanceModifier.fillMaxSize()) {
        GameHeader(snapshot, role, style)
        Spacer(GlanceModifier.height(4.dp))
        StaminaValue(role, now, style, 22)
        Label(fullText(snapshot, role, now), style.palette.text2, (12 * style.scale).sp)
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
    val visible = config?.visibleItems?.takeIf { it.isNotEmpty() }
    val items = (visible?.mapNotNull { key -> role.items.firstOrNull { it.key == key } }
        ?: role.items).take(MAX_ITEMS)
    Column(modifier = GlanceModifier.fillMaxSize()) {
        Row(verticalAlignment = Alignment.CenterVertically, modifier = GlanceModifier.fillMaxWidth()) {
            Box(modifier = GlanceModifier.defaultWeight()) { GameHeader(snapshot, role, style) }
            RefreshButton(style)
        }
        Spacer(GlanceModifier.height(6.dp))
        StaminaValue(role, now, style, 26)
        StaminaBar(role, now, style)
        Label(fullText(snapshot, role, now), style.palette.text2, (12 * style.scale).sp)
        Spacer(GlanceModifier.height(8.dp))
        items.forEach { item ->
            Row(modifier = GlanceModifier.fillMaxWidth()) {
                Box(modifier = GlanceModifier.defaultWeight()) {
                    Label(snapshot.label(item.key), style.palette.text2, (12 * style.scale).sp)
                }
                Label(itemValue(snapshot, item, now), style.palette.text, (12 * style.scale).sp, bold = true)
            }
        }
    }
}

@Composable
private fun LargeContent(snapshot: WidgetSnapshot, style: WidgetStyle) {
    val now = Instant.now()
    Column(modifier = GlanceModifier.fillMaxSize()) {
        snapshot.roles.take(MAX_LARGE_ROLES).forEach { role ->
            val accent = style.accent ?: WidgetTokens.accents[role.game] ?: WidgetTokens.lime
            val roleStyle = style.copy(accent = accent)
            Row(verticalAlignment = Alignment.CenterVertically, modifier = GlanceModifier.fillMaxWidth()) {
                Dot(accent)
                Spacer(GlanceModifier.width(6.dp))
                Box(modifier = GlanceModifier.defaultWeight()) {
                    Label(snapshot.label(role.stamina.key), style.palette.text, (13 * style.scale).sp, bold = true)
                }
                Label(
                    "${role.stamina.currentAt(now)}/${role.stamina.max}  ${fullText(snapshot, role, now)}",
                    style.palette.text2,
                    (12 * style.scale).sp,
                )
            }
            StaminaBar(role, now, roleStyle)
            Spacer(GlanceModifier.height(6.dp))
        }
        Row(verticalAlignment = Alignment.CenterVertically, modifier = GlanceModifier.fillMaxWidth()) {
            Box(modifier = GlanceModifier.defaultWeight()) {
                Label(
                    snapshot.label("checkedIn")
                        .replace("{done}", snapshot.checkInDone.toString())
                        .replace("{total}", snapshot.checkInTotal.toString()),
                    style.palette.text2,
                    (12 * style.scale).sp,
                )
            }
            RefreshButton(style)
        }
    }
}

@Composable
private fun GameHeader(snapshot: WidgetSnapshot, role: WidgetRole, style: WidgetStyle) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Dot(style.accent ?: WidgetTokens.lime)
        Spacer(GlanceModifier.width(6.dp))
        Label(snapshot.label("game.${role.game}"), style.palette.text2, (12 * style.scale).sp, bold = true)
    }
}

@Composable
private fun StaminaValue(role: WidgetRole, now: Instant, style: WidgetStyle, size: Int) {
    Row(verticalAlignment = Alignment.Bottom) {
        Label(role.stamina.currentAt(now).toString(), style.palette.text, (size * style.scale).sp, bold = true)
        Label("/${role.stamina.max}", style.palette.text2, (13 * style.scale).sp)
    }
}

@Composable
private fun StaminaBar(role: WidgetRole, now: Instant, style: WidgetStyle) {
    val max = role.stamina.max.coerceAtLeast(1)
    LinearProgressIndicator(
        progress = role.stamina.currentAt(now).toFloat() / max,
        modifier = GlanceModifier.fillMaxWidth().height(6.dp),
        color = ColorProvider(style.accent ?: WidgetTokens.lime),
        backgroundColor = ColorProvider(style.palette.track),
    )
}

@Composable
private fun RefreshButton(style: WidgetStyle) {
    Image(
        provider = ImageProvider(R.drawable.ic_widget_refresh),
        contentDescription = LocalContext.current.getString(R.string.widget_refresh),
        colorFilter = ColorFilter.tint(ColorProvider(style.palette.text2)),
        modifier = GlanceModifier.size(20.dp).clickable(actionRunCallback<RefreshAction>()),
    )
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

private fun fullText(snapshot: WidgetSnapshot, role: WidgetRole, now: Instant): String =
    if (role.stamina.isFullAt(now)) snapshot.label("full")
    else "${snapshot.label("full")} ${WidgetSnapshot.clockTime(role.stamina.fullAt)}"

private fun itemValue(snapshot: WidgetSnapshot, item: WidgetItem, now: Instant): String {
    val state = item.state
    val doneAt = item.doneAt
    return when {
        item.key == "videoStore" && state != null -> snapshot.label("videoStore.$state")
        item.key == "scratchCard" -> if (state == "done") snapshot.label("done") else "0/1"
        item.key == "realm" -> "${item.value ?: 0}/${item.max ?: 0}"
        doneAt != null && !now.isBefore(doneAt) ->
            snapshot.label(if (item.key == "transformer") "ready" else "done")
        doneAt != null -> WidgetSnapshot.clockTime(doneAt)
        else -> "${item.value ?: 0}/${item.max ?: 0}"
    }
}
