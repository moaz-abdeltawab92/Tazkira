package com.moaz.tazkira.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.updateAll
import com.moaz.tazkira.MainActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * BroadcastReceiver that backs the PrayerGlanceWidget.
 *
 * Responsibilities:
 * 1. Provide the [GlanceAppWidget] instance to the Glance framework
 *    (via [glanceAppWidget] property).
 * 2. Handle the standard [android.appwidget.AppWidgetManager.ACTION_APPWIDGET_UPDATE]
 *    broadcast sent by the OS on its scheduled update interval.
 * 3. Handle the custom [MainActivity.ACTION_WIDGET_UPDATE] broadcast sent by
 *    the Flutter platform channel handler when new prayer data is available,
 *    triggering an immediate Glance content refresh.
 *
 * AndroidManifest registration and intent-filter declarations are in Task 19.
 */
class PrayerWidgetReceiver : GlanceAppWidgetReceiver() {

    companion object {
        /**
         * Shared coroutine scope for widget update work.
         *
         * A single scope is used across all broadcast deliveries rather than
         * creating a new scope per broadcast (which would leak if broadcasts
         * arrive rapidly). SupervisorJob ensures one failed update does not
         * cancel pending updates from other broadcasts.
         *
         * The scope uses Dispatchers.Default — updateAll() is a Glance suspend
         * function that dispatches its own work; using Default here avoids
         * blocking the Main thread while Glance schedules the update.
         *
         * This scope intentionally lives for the process lifetime. BroadcastReceivers
         * have no destruction callback, so there is no correct cancellation point.
         * The scope is bounded by the process lifecycle, which is acceptable for
         * a lightweight widget update operation.
         */
        private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    }

    /** Provides the widget implementation to the Glance framework. */
    override val glanceAppWidget: GlanceAppWidget = PrayerGlanceWidget()

    /**
     * Called for both the OS-scheduled update and the custom Flutter broadcast.
     *
     * [GlanceAppWidgetReceiver.onReceive] already handles
     * [ACTION_APPWIDGET_UPDATE] and delegates to [GlanceAppWidget.update].
     * We override to add handling for boot recovery, alarms, and widgets state.
     */
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        val action = intent.action

        when (action) {
            MainActivity.ACTION_WIDGET_UPDATE,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            WidgetAlarmScheduler.ACTION_ALARM_UPDATE -> {
                WidgetAlarmScheduler.scheduleNextUpdate(context)
                updateAll(context)
            }
            AppWidgetManager.ACTION_APPWIDGET_UPDATE,
            AppWidgetManager.ACTION_APPWIDGET_ENABLED -> {
                WidgetAlarmScheduler.scheduleNextUpdate(context)
            }
            AppWidgetManager.ACTION_APPWIDGET_DISABLED -> {
                WidgetAlarmScheduler.cancelUpdate(context)
            }
        }
    }

    /**
     * Requests an immediate update of all active widget instances.
     * Uses the shared [scope] — no new scope is created per broadcast.
     */
    private fun updateAll(context: Context) {
        scope.launch {
            try {
                glanceAppWidget.updateAll(context)
            } catch (_: Exception) {
                // Non-fatal — widget will refresh on next OS-scheduled update.
            }
        }
    }
}
