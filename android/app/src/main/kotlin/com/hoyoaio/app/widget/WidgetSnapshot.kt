package com.hoyoaio.app.widget

import android.content.SharedPreferences
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

data class WidgetStamina(
    val key: String,
    val current: Int,
    val max: Int,
    val fetchedAt: Instant,
    val fullAt: Instant,
    val recoverySeconds: Long,
) {
    fun currentAt(now: Instant): Int {
        if (current >= max || !now.isAfter(fetchedAt) || recoverySeconds <= 0) return current
        val remaining = fullAt.epochSecond - now.epochSecond
        if (remaining <= 0) return max
        val missing = (remaining + recoverySeconds - 1) / recoverySeconds
        return (max - missing.toInt()).coerceIn(current, max)
    }

    fun isFullAt(now: Instant): Boolean = currentAt(now) >= max
}

data class WidgetItem(
    val key: String,
    val value: Int?,
    val max: Int?,
    val doneAt: Instant?,
    val state: String?,
)

data class WidgetRole(
    val roleId: Int,
    val game: String,
    val name: String,
    val uid: String?,
    val fetchedAt: Instant,
    val stale: Boolean,
    val stamina: WidgetStamina,
    val items: List<WidgetItem>,
)

data class WidgetConfig(
    val widgetId: Int,
    val roleId: Int?,
    val theme: String,
    val opacity: Float,
    val accent: String,
    val fontSize: String,
    val visibleItems: List<String>,
)

data class WidgetSnapshot(
    val roles: List<WidgetRole>,
    val checkInDone: Int,
    val checkInTotal: Int,
    val widgets: List<WidgetConfig>,
    val labels: Map<String, String>,
) {
    fun label(key: String): String = labels[key] ?: key

    fun config(widgetId: Int): WidgetConfig? = widgets.firstOrNull { it.widgetId == widgetId }

    fun role(roleId: Int?): WidgetRole? =
        roles.firstOrNull { it.roleId == roleId } ?: roles.firstOrNull()

    companion object {
        const val KEY = "hoyo_aio_snapshot"

        private val clock = DateTimeFormatter.ofPattern("HH:mm")

        fun clockTime(instant: Instant): String =
            clock.format(instant.atZone(ZoneId.systemDefault()))

        fun read(preferences: SharedPreferences): WidgetSnapshot? {
            val raw = preferences.getString(KEY, null) ?: return null
            return try {
                parse(JSONObject(raw))
            } catch (error: JSONException) {
                null
            }
        }

        private fun parse(json: JSONObject): WidgetSnapshot {
            val checkIn = json.getJSONObject("check_in")
            val labels = json.getJSONObject("labels")
            return WidgetSnapshot(
                roles = json.getJSONArray("roles").objects().map(::parseRole),
                checkInDone = checkIn.getInt("done"),
                checkInTotal = checkIn.getInt("total"),
                widgets = json.getJSONArray("widgets").objects().map(::parseConfig),
                labels = labels.keys().asSequence().associateWith { labels.getString(it) },
            )
        }

        private fun parseRole(json: JSONObject): WidgetRole {
            val stamina = json.getJSONObject("stamina")
            return WidgetRole(
                roleId = json.getInt("role_id"),
                game = json.getString("game"),
                name = json.getString("name"),
                uid = json.optStringOrNull("uid"),
                fetchedAt = Instant.parse(json.getString("fetched_at")),
                stale = json.optBoolean("stale"),
                stamina = WidgetStamina(
                    key = stamina.getString("key"),
                    current = stamina.getInt("current"),
                    max = stamina.getInt("max"),
                    fetchedAt = Instant.parse(stamina.getString("fetched_at")),
                    fullAt = Instant.parse(stamina.getString("full_at")),
                    recoverySeconds = stamina.getLong("recovery_seconds"),
                ),
                items = json.getJSONArray("items").objects().map(::parseItem),
            )
        }

        private fun parseItem(json: JSONObject) = WidgetItem(
            key = json.getString("key"),
            value = if (json.isNull("value")) null else json.optInt("value"),
            max = if (json.isNull("max")) null else json.optInt("max"),
            doneAt = json.optStringOrNull("done_at")?.let(Instant::parse),
            state = json.optStringOrNull("state"),
        )

        private fun parseConfig(json: JSONObject) = WidgetConfig(
            widgetId = json.getInt("widget_id"),
            roleId = if (json.isNull("role_id")) null else json.optInt("role_id"),
            theme = json.optString("theme", "system"),
            opacity = json.optDouble("opacity", 1.0).toFloat(),
            accent = json.optString("accent", "match"),
            fontSize = json.optString("font_size", "medium"),
            visibleItems = json.optJSONArray("visible_items")?.strings() ?: emptyList(),
        )

        private fun JSONArray.objects(): List<JSONObject> = (0 until length()).map { getJSONObject(it) }

        private fun JSONArray.strings(): List<String> = (0 until length()).map { getString(it) }

        private fun JSONObject.optStringOrNull(name: String): String? =
            if (!has(name) || isNull(name)) null else getString(name)
    }
}
