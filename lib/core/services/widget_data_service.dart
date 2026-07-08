import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:tazkira_app/core/models/prayer_data_snapshot.dart';

/// Thin serialisation service that publishes pre-calculated prayer data to
/// native Home Screen widgets (iOS WidgetKit / Android Jetpack Glance).
///
/// Responsibilities (what this service DOES):
/// - Accept a [PrayerDataSnapshot] built by the caller from already-available
///   prayer data.
/// - Write the snapshot to native shared storage via the platform channel.
/// - Reload widgets only when the snapshot content has actually changed.
///
/// Responsibilities (what this service does NOT do):
/// - Calculate prayer times — caller owns all calculation.
/// - Manage location or GPS — caller owns all location work.
/// - Register lifecycle observers — caller owns all lifecycle management.
/// - Schedule timers — caller owns all timing.
/// - Retry on failure — failures are logged; the next natural publication
///   (next timer tick / app resume) acts as the implicit retry.
class WidgetDataService {
  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------

  WidgetDataService._();
  static final WidgetDataService instance = WidgetDataService._();

  // ---------------------------------------------------------------------------
  // Platform channel
  // ---------------------------------------------------------------------------

  static const MethodChannel _channel =
      MethodChannel('com.moaz.tazkira/widget_channel');

  // ---------------------------------------------------------------------------
  // Change-detection state
  // ---------------------------------------------------------------------------

  /// The last snapshot successfully written to native storage.
  /// Used to skip writes and widget reloads when data has not changed.
  PrayerDataSnapshot _lastSnapshot = PrayerDataSnapshot.empty();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Publishes [snapshot] to native shared storage if its content differs
  /// from the previously published snapshot, then requests a widget reload.
  ///
  /// Silently returns without writing when:
  /// - [snapshot] fails [PrayerDataSnapshot.isValid].
  /// - [snapshot] content is identical to [_lastSnapshot] (no change).
  ///
  /// On platform channel failures the error is logged and the method returns
  /// normally — the next call from the existing timer or app-resume path
  /// acts as the implicit retry.
  Future<void> publishSnapshot(PrayerDataSnapshot snapshot) async {
    // Guard: snapshot must carry valid data.
    if (!snapshot.isValid()) {
      debugPrint('[WidgetDataService] Skipping invalid snapshot.');
      return;
    }

    // Guard: only write when display-relevant data has actually changed.
    if (snapshot.contentEquals(_lastSnapshot)) {
      debugPrint('[WidgetDataService] Snapshot unchanged — skipping write.');
      return;
    }

    try {
      await _channel.invokeMethod<bool>(
        'writeWidgetData',
        snapshot.toJson(),
      );
      _lastSnapshot = snapshot;
      debugPrint('[WidgetDataService] Snapshot written: $snapshot');
      await _reloadWidgets();
    } on MissingPluginException {
      // Platform channel not registered (e.g. running on web or in unit tests).
      debugPrint(
          '[WidgetDataService] Platform channel unavailable — skipping.');
    } catch (e) {
      // Any other failure (PlatformException, etc.) is logged.
      // No retry timer is scheduled — the next natural call will retry.
      debugPrint('[WidgetDataService] Failed to write snapshot: $e');
    }
  }

  /// Returns true when the native widget is installed and active.
  ///
  /// Always returns false on platforms that do not support widgets or when
  /// the channel is unavailable.
  Future<bool> isWidgetInstalled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isWidgetInstalled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _reloadWidgets() async {
    try {
      await _channel.invokeMethod<void>('reloadWidgets');
      debugPrint('[WidgetDataService] Widget reload requested.');
    } on MissingPluginException {
      debugPrint('[WidgetDataService] reloadWidgets: channel unavailable.');
    } catch (e) {
      debugPrint('[WidgetDataService] reloadWidgets failed: $e');
    }
  }
}
