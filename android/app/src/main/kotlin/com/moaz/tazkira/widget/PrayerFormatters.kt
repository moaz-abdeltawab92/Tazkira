package com.moaz.tazkira.widget

import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

/**
 * Pure formatting utilities shared by all widget components.
 * No I/O, no SharedPreferences access, no state.
 *
 * Requires API 26+ (java.time). The app's build.gradle already enables
 * coreLibraryDesugaringEnabled = true, which backports java.time to
 * API 23+ via desugar_jdk_libs.
 */
object PrayerFormatters {

    // MARK: - Time Formatting

    /**
     * Converts an ISO-8601 UTC string to a local 12-hour Arabic time string.
     *
     * Format: "HH:mm ص" (AM) or "HH:mm م" (PM), matching the app's
     * existing _formatTime() logic in PrayerTimesCardsWidget.dart.
     *
     * Returns "—" for null, blank, or unparseable input so widget views
     * never display a blank field or crash on bad data.
     */
    fun formatTime(isoString: String?): String {
        if (isoString.isNullOrBlank()) return "—"

        return try {
            val instant = Instant.parse(isoString)
            val localTime = instant.atZone(ZoneId.systemDefault()).toLocalTime()

            val hour24 = localTime.hour
            val minute = localTime.minute

            val hour12 = when {
                hour24 == 0  -> 12
                hour24 > 12  -> hour24 - 12
                else         -> hour24
            }

            // Arabic AM/PM suffix — matches Dart: hour >= 12 ? 'م' : 'ص'
            val period = if (hour24 >= 12) "م" else "ص"

            "%02d:%02d %s".format(hour12, minute, period)
        } catch (_: Exception) {
            "—"
        }
    }

    // MARK: - Staleness Detection

    /**
     * Returns true when the snapshot is strictly older than 30 days.
     * Since we precalculate 30 days of prayer times, we allow the snapshot
     * to remain valid up to 720 hours (30 * 24 hours).
     *
     * Returns false for null, blank, or unparseable timestamps so that
     * missing timestamps fall back to the placeholder state (handled by
     * callers) rather than the staleness indicator.
     */
    fun isStale(isoTimestamp: String?): Boolean {
        if (isoTimestamp.isNullOrBlank()) return false

        return try {
            val snapshotTime = Instant.parse(isoTimestamp)
            val ageHours = ChronoUnit.HOURS.between(snapshotTime, Instant.now())
            ageHours > 720
        } catch (_: Exception) {
            false
        }
    }
}
