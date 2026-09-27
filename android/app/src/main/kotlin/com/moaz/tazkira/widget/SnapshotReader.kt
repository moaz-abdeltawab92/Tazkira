package com.moaz.tazkira.widget

import android.content.Context
import org.json.JSONObject

/**
 * Reads the prayer data snapshot written by the Flutter app via the
 * platform channel handler in MainActivity.
 *
 * Data is stored in SharedPreferences ("FlutterSharedPreferences") under
 * the key "flutter.tazkira_widget_data" as a JSON string.
 *
 * This is the single point of access to shared storage within the widget
 * package — no other file reads SharedPreferences directly.
 */

// MARK: - PrayerSnapshot

/**
 * Represents the prayer data written by the Flutter app.
 * All times are ISO-8601 UTC strings — use [PrayerFormatters] to convert
 * them to display strings.
 */
data class DailyPrayerSnapshot(
    val date: String,
    val fajr: String,
    val dhuhr: String,
    val asr: String,
    val maghrib: String,
    val isha: String,
    val hijriDate: String
)

data class PrayerSnapshot(
    val date: String,
    val fajr: String,
    val dhuhr: String,
    val asr: String,
    val maghrib: String,
    val isha: String,
    val hijriDate: String,
    val tomorrowDate: String,
    val tomorrowFajr: String,
    val tomorrowDhuhr: String,
    val tomorrowAsr: String,
    val tomorrowMaghrib: String,
    val tomorrowIsha: String,
    val tomorrowHijriDate: String,
    val nextPrayerName: String,
    val nextPrayerTime: String,
    val snapshotTimestamp: String,
    val days: List<DailyPrayerSnapshot> = emptyList()
)

// MARK: - SnapshotReader

object SnapshotReader {

    /** SharedPreferences file written by Flutter's shared_preferences plugin. */
    private const val PREFS_FILE = "FlutterSharedPreferences"

    /**
     * Key written by the Flutter platform channel handler in MainActivity.
     * The "flutter." prefix is added by Flutter's shared_preferences plugin.
     */
    private const val STORAGE_KEY = "flutter.tazkira_widget_data"

    /**
     * Reads and parses the latest prayer snapshot from SharedPreferences.
     *
     * Returns null when:
     * - The key is absent (app has never been opened since install).
     * - The JSON string is malformed.
     * - Any required field is missing or empty.
     */
    fun read(context: Context): PrayerSnapshot? {
        return try {
            val prefs = context.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
            val jsonString = prefs.getString(STORAGE_KEY, null) ?: return null
            parse(jsonString)
        } catch (_: Exception) {
            null
        }
    }

    private fun parse(jsonString: String): PrayerSnapshot? {
        return try {
            val json = JSONObject(jsonString)

            val date              = json.optString("date")
            val fajr              = json.optString("fajr").takeIf { it.isNotEmpty() } ?: return null
            val dhuhr             = json.optString("dhuhr").takeIf { it.isNotEmpty() } ?: return null
            val asr               = json.optString("asr").takeIf { it.isNotEmpty() } ?: return null
            val maghrib           = json.optString("maghrib").takeIf { it.isNotEmpty() } ?: return null
            val isha              = json.optString("isha").takeIf { it.isNotEmpty() } ?: return null
            val nextPrayerName    = json.optString("nextPrayerName").takeIf { it.isNotEmpty() } ?: return null
            val nextPrayerTime    = json.optString("nextPrayerTime").takeIf { it.isNotEmpty() } ?: return null
            val hijriDate         = json.optString("hijriDate")          // empty is acceptable
            
            val tomorrowDate      = json.optString("tomorrowDate")
            val tomorrowFajr      = json.optString("tomorrowFajr")
            val tomorrowDhuhr     = json.optString("tomorrowDhuhr")
            val tomorrowAsr       = json.optString("tomorrowAsr")
            val tomorrowMaghrib   = json.optString("tomorrowMaghrib")
            val tomorrowIsha      = json.optString("tomorrowIsha")
            val tomorrowHijriDate = json.optString("tomorrowHijriDate")
            
            val snapshotTimestamp = json.optString("snapshotTimestamp")  // empty is acceptable

            val daysJson = json.optJSONArray("days")
            val daysList = mutableListOf<DailyPrayerSnapshot>()
            if (daysJson != null) {
                for (i in 0 until daysJson.length()) {
                    val dayObj = daysJson.optJSONObject(i) ?: continue
                    daysList.add(
                        DailyPrayerSnapshot(
                            date = dayObj.optString("date"),
                            fajr = dayObj.optString("fajr"),
                            dhuhr = dayObj.optString("dhuhr"),
                            asr = dayObj.optString("asr"),
                            maghrib = dayObj.optString("maghrib"),
                            isha = dayObj.optString("isha"),
                            hijriDate = dayObj.optString("hijriDate")
                        )
                    )
                }
            }

            PrayerSnapshot(
                date              = date,
                fajr              = fajr,
                dhuhr             = dhuhr,
                asr               = asr,
                maghrib           = maghrib,
                isha              = isha,
                hijriDate         = hijriDate,
                tomorrowDate      = tomorrowDate,
                tomorrowFajr      = tomorrowFajr,
                tomorrowDhuhr     = tomorrowDhuhr,
                tomorrowAsr       = tomorrowAsr,
                tomorrowMaghrib   = tomorrowMaghrib,
                tomorrowIsha      = tomorrowIsha,
                tomorrowHijriDate = tomorrowHijriDate,
                nextPrayerName    = nextPrayerName,
                nextPrayerTime    = nextPrayerTime,
                snapshotTimestamp = snapshotTimestamp,
                days              = daysList
            )
        } catch (_: Exception) {
            null
        }
    }
}
