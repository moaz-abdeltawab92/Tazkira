package com.moaz.tazkira.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/**
 * Handles scheduling of exact native alarms using Android's AlarmManager.
 * Alarms are scheduled at:
 *  1. The next upcoming prayer transition time (today or tomorrow).
 *  2. Local midnight (00:00 AM) to trigger date rollover for the widget.
 *
 * Avoids periodic polling (unlike Azkari's 15-minute polling) to save battery,
 * waking the device only when a visual transition is required.
 */
object WidgetAlarmScheduler {

    private const val TAG = "WidgetAlarmScheduler"
    private const val REQUEST_CODE = 8888
    
    /** Custom broadcast action targeting PrayerWidgetReceiver. */
    const val ACTION_ALARM_UPDATE = "com.moaz.tazkira.ALARM_WIDGET_UPDATE"

    /**
     * Identifies the closest future transition (prayer or midnight) from the
     * snapshot and schedules an AlarmManager alarm.
     */
    fun scheduleNextUpdate(context: Context) {
        val snapshot = SnapshotReader.read(context)
        if (snapshot == null) {
            Log.w(TAG, "No snapshot available, cannot schedule next update.")
            return
        }

        val now = Instant.now()

        // 1. Gather all potential transition times from today and tomorrow
        val transitionStrings = listOf(
            snapshot.fajr,
            snapshot.dhuhr,
            snapshot.asr,
            snapshot.maghrib,
            snapshot.isha,
            snapshot.tomorrowFajr,
            snapshot.tomorrowDhuhr,
            snapshot.tomorrowAsr,
            snapshot.tomorrowMaghrib,
            snapshot.tomorrowIsha
        )

        val transitionInstants = mutableListOf<Instant>()

        // Parse valid prayer times
        for (timeStr in transitionStrings) {
            if (timeStr.isNotBlank()) {
                try {
                    transitionInstants.add(Instant.parse(timeStr))
                } catch (e: Exception) {
                    Log.e(TAG, "Error parsing transition time: $timeStr", e)
                }
            }
        }

        // 2. Add local midnight rollover transition (00:00 AM tomorrow local time)
        try {
            val midnightLocal = LocalDate.now().plusDays(1)
                .atStartOfDay(ZoneId.systemDefault())
                .toInstant()
            transitionInstants.add(midnightLocal)
        } catch (e: Exception) {
            Log.e(TAG, "Error calculating local midnight transition", e)
        }

        // 3. Find the closest upcoming transition in the future
        val nextTransition = transitionInstants
            .filter { it.isAfter(now) }
            .minOrNull()

        if (nextTransition == null) {
            Log.w(TAG, "No future transition times found in snapshot.")
            return
        }

        val triggerTimeMillis = nextTransition.toEpochMilli()
        Log.i(TAG, "Next scheduled widget transition: $nextTransition ($triggerTimeMillis ms)")

        // 4. Register the alarm with AlarmManager
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, PrayerWidgetReceiver::class.java).apply {
            action = ACTION_ALARM_UPDATE
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Cancel any previous alarm
        alarmManager.cancel(pendingIntent)

        // Schedule exact alarm with proper try-catch wrapper for Android 12+ compatibility
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerTimeMillis,
                        pendingIntent
                    )
                    Log.d(TAG, "Scheduled exact wakeup alarm successfully.")
                } else {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerTimeMillis,
                        pendingIntent
                    )
                    Log.d(TAG, "Exact alarm permission denied. Scheduled inexact alarm.")
                }
            } else {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTimeMillis,
                    pendingIntent
                )
                Log.d(TAG, "Scheduled exact wakeup alarm successfully.")
            }
        } catch (e: SecurityException) {
            Log.w(TAG, "SecurityException while scheduling exact alarm. Falling back to inexact alarm.", e)
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerTimeMillis,
                pendingIntent
            )
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error scheduling alarm", e)
        }
    }

    /**
     * Cancels any currently scheduled update alarm.
     * Called when the last widget instance is removed from the home screen.
     */
    fun cancelUpdate(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, PrayerWidgetReceiver::class.java).apply {
            action = ACTION_ALARM_UPDATE
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
        Log.i(TAG, "Update alarms cancelled.")
    }
}
