package com.moaz.tazkira

import android.content.Context
import android.content.Intent
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : AudioServiceActivity() {

    companion object {
        // Must match WidgetDataService._channel name in Dart.
        private const val WIDGET_CHANNEL = "com.moaz.tazkira/widget_channel"

        // SharedPreferences file written by Flutter's shared_preferences plugin.
        // The flutter. prefix is added by the plugin for all keys.
        private const val PREFS_FILE = "FlutterSharedPreferences"
        private const val WIDGET_DATA_KEY = "flutter.tazkira_widget_data"

        // Custom broadcast action listened to by PrayerWidgetReceiver (Phase 6).
        // Defined here so the channel handler can send it without depending on
        // the receiver class directly.
        const val ACTION_WIDGET_UPDATE = "com.moaz.tazkira.WIDGET_UPDATE"
    }

    // -------------------------------------------------------------------------
    // Platform Channel Registration
    // -------------------------------------------------------------------------

    /**
     * Called by the Flutter engine after it attaches to this activity.
     *
     * AudioServiceActivity -> FlutterActivity -> FlutterFragmentActivity all
     * forward super.configureFlutterEngine(), so the audio plugin remains fully
     * registered. The widget channel is added on top without any interference.
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        registerWidgetChannel(flutterEngine)
    }

    // -------------------------------------------------------------------------
    // Widget Channel
    // -------------------------------------------------------------------------

    private fun registerWidgetChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WIDGET_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "writeWidgetData"   -> handleWriteWidgetData(call.arguments, result)
                "reloadWidgets"     -> handleReloadWidgets(result)
                "isWidgetInstalled" -> handleIsWidgetInstalled(result)
                else                -> result.notImplemented()
            }
        }
    }

    // -------------------------------------------------------------------------
    // Channel Handlers
    // -------------------------------------------------------------------------

    /**
     * Writes the prayer snapshot as a JSON string to SharedPreferences under
     * [WIDGET_DATA_KEY], then broadcasts [ACTION_WIDGET_UPDATE] so the Glance
     * widget receiver can request an immediate UI refresh.
     *
     * Uses .apply() (async commit) — consistent with how Flutter's own
     * shared_preferences plugin writes data on Android.
     *
     * Returns true on success, or a FlutterError on failure.
     */
    private fun handleWriteWidgetData(arguments: Any?, result: MethodChannel.Result) {
        @Suppress("UNCHECKED_CAST")
        val data = arguments as? Map<String, Any>
        if (data == null) {
            result.error(
                "INVALID_ARGS",
                "writeWidgetData expects a Map argument",
                null
            )
            return
        }

        try {
            val jsonString = JSONObject(data).toString()

            getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
                .edit()
                .putString(WIDGET_DATA_KEY, jsonString)
                .apply()

            // Notify the widget receiver. Package-scoped to prevent external apps
            // from triggering widget updates. The receiver is registered in
            // AndroidManifest in Phase 7 (Android Manifest & build config).
            sendBroadcast(
                Intent(ACTION_WIDGET_UPDATE).setPackage(packageName)
            )

            result.success(true)
        } catch (e: Exception) {
            result.error(
                "WRITE_ERROR",
                "Failed to write widget data: ${e.message}",
                null
            )
        }
    }

    /**
     * Re-sends [ACTION_WIDGET_UPDATE] to request an immediate widget refresh
     * without writing new data. Useful when the Dart side calls reloadWidgets()
     * independently of a data write.
     */
    private fun handleReloadWidgets(result: MethodChannel.Result) {
        try {
            sendBroadcast(
                Intent(ACTION_WIDGET_UPDATE).setPackage(packageName)
            )
        } catch (_: Exception) {
            // Non-fatal. Widget will refresh on next OS-scheduled update.
        }
        result.success(null)
    }

    /**
     * Returns true when at least one Tazkira widget instance is active on the
     * home screen. Uses the fully-qualified receiver class name so this compiles
     * cleanly before PrayerWidgetReceiver exists — returns false until the
     * receiver is registered (Phase 6).
     */
    private fun handleIsWidgetInstalled(result: MethodChannel.Result) {
        try {
            val manager = android.appwidget.AppWidgetManager.getInstance(this)
            val component = android.content.ComponentName(
                this,
                "com.moaz.tazkira.widget.PrayerWidgetReceiver"
            )
            result.success(manager.getAppWidgetIds(component).isNotEmpty())
        } catch (_: Exception) {
            result.success(false)
        }
    }
}
