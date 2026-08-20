import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tazkira_app/core/services/notification_scheduler.dart';
import 'package:tazkira_app/core/services/notification_cancellation_service.dart';
import 'package:flutter/foundation.dart';

class PrayerReminderScheduler {
  static const int _normalStartId =
      1001; // Fajr: 1001, Dhuhr: 1002, Asr: 1003, Maghrib: 1004, Isha: 1005
  static const int _smartStartId =
      2001; // Fajr: 2001, Dhuhr: 2002, Asr: 2003, Maghrib: 2004, Isha: 2005
  static const String _prayerChannelId = 'prayer_reminders';
  static final List<String> _prayers = [
    'الفجر',
    'الظهر',
    'العصر',
    'المغرب',
    'العشاء'
  ];

  // Race condition protection flags
  static bool _isScheduling = false;
  static bool _needsScheduleAgain = false;

  /// Reschedules all today's normal and smart reminders safely.
  /// Guarantees that only one operation runs at a time and no request is lost.
  static Future<void> scheduleAllReminders() async {
    if (_isScheduling) {
      debugPrint(
          'scheduleAllReminders: Scheduling already in progress. Queueing request.');
      _needsScheduleAgain = true;
      return;
    }

    _isScheduling = true;

    try {
      await _executeScheduleAllReminders();
    } finally {
      _isScheduling = false;
      if (_needsScheduleAgain) {
        debugPrint(
            'scheduleAllReminders: Triggering queued rescheduling request.');
        _needsScheduleAgain = false;
        // Schedule next execution asynchronously to avoid stack overflow
        Future.microtask(() => scheduleAllReminders());
      }
    }
  }

  static Future<void> _executeScheduleAllReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Perform daily reset check
      await checkAndResetDailyPrayers(prefs);

      final bool prayerRemindersEnabled =
          prefs.getBool('prayer_reminders_enabled') ?? false;
      final bool smartRemindersEnabled =
          prefs.getBool('smart_prayer_reminders_enabled') ?? false;

      // Always cancel all existing smart and normal reminders first to avoid duplicates
      await NotificationCancellationService.cancelAllNormalReminders();
      await NotificationCancellationService.cancelAllSmartReminders();

      // If both are disabled, we return immediately
      if (!prayerRemindersEnabled && !smartRemindersEnabled) {
        debugPrint(
            'scheduleAllReminders: Both normal and smart prayer reminders are disabled.');
        return;
      }

      // 2. Get location / coordinates (either cached or fresh)
      Coordinates? coordinates = await _getCoordinates(prefs);
      if (coordinates == null) {
        debugPrint(
            'scheduleAllReminders: No coordinates available. Cannot schedule.');
        return;
      }

      // 3. Calculate today's prayer times
      final params = CalculationMethod.egyptian.getParameters();
      params.madhab = Madhab.shafi;
      final now = DateTime.now();
      final dateComponents = DateComponents(now.year, now.month, now.day);
      final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

      final List<DateTime> prayerDateTimes = [
        prayerTimes.fajr,
        prayerTimes.dhuhr,
        prayerTimes.asr,
        prayerTimes.maghrib,
        prayerTimes.isha,
      ];

      for (int i = 0; i < _prayers.length; i++) {
        final String prayerName = _prayers[i];
        final DateTime time = prayerDateTimes[i];

        // -------------------------------------------------------------
        // A. Normal Reminder Scheduling
        // -------------------------------------------------------------
        bool shouldScheduleNormal = false;
        if (prayerRemindersEnabled) {
          if (smartRemindersEnabled) {
            // If smart reminders are also enabled:
            // Fajr normal is scheduled by default (no previous prayer today to check)
            if (i == 0) {
              shouldScheduleNormal = true;
            } else {
              // Other prayers only scheduled if the previous prayer is completed
              final String prevPrayerName = _prayers[i - 1];
              final bool isPrevCompleted =
                  prefs.getBool(prevPrayerName) ?? false;
              if (isPrevCompleted) {
                shouldScheduleNormal = true;
              }
            }
          } else {
            // If smart reminders are disabled, schedule normal reminders unconditionally
            shouldScheduleNormal = true;
          }
        }

        if (shouldScheduleNormal) {
          final scheduledClientTime =
              time.subtract(const Duration(minutes: 15));
          final id = _normalStartId + i;
          await NotificationScheduler.schedule(
            id: id,
            title: prayerName,
            body: 'تبقّى 15 دقيقة على صلاة $prayerName ',
            scheduledTime: scheduledClientTime,
            channelId: _prayerChannelId,
            payload: 'prayer_$prayerName',
          );
        }

        // -------------------------------------------------------------
        // B. Smart Reminder Scheduling
        // -------------------------------------------------------------
        bool shouldScheduleSmart = false;
        if (smartRemindersEnabled) {
          // Schedule only if not completed today
          final bool isCompleted = prefs.getBool(prayerName) ?? false;
          if (!isCompleted) {
            shouldScheduleSmart = true;
          }
        }

        if (shouldScheduleSmart) {
          DateTime? scheduledSmartTime;
          String title = 'لسه مصلتش $prayerName؟';
          String body = '';

          // Timing rules:
          // - Fajr: 30 minutes before Dhuhr
          // - Dhuhr: 30 minutes before Asr
          // - Asr: 30 minutes before Maghrib
          // - Maghrib: 30 minutes before Isha
          // - Isha: 2 hours after Isha starts
          switch (i) {
            case 0:
              scheduledSmartTime =
                  prayerDateTimes[1].subtract(const Duration(minutes: 30));
              body = 'اقترب أذان الظهر.';
              break;
            case 1:
              scheduledSmartTime =
                  prayerDateTimes[2].subtract(const Duration(minutes: 30));
              body = 'اقترب أذان العصر.';
              break;
            case 2:
              scheduledSmartTime =
                  prayerDateTimes[3].subtract(const Duration(minutes: 30));
              body = 'اقترب أذان المغرب.';
              break;
            case 3:
              scheduledSmartTime =
                  prayerDateTimes[4].subtract(const Duration(minutes: 30));
              body = 'اقترب أذان العشاء.';
              break;
            case 4:
              scheduledSmartTime =
                  prayerDateTimes[4].add(const Duration(hours: 2));
              body = 'متنساش تصليها قبل ما تنام.';
              break;
          }

          if (scheduledSmartTime != null) {
            final id = _smartStartId + i;
            await NotificationScheduler.schedule(
              id: id,
              title: title,
              body: body,
              scheduledTime: scheduledSmartTime,
              channelId: _prayerChannelId,
              payload: 'smart_prayer_$prayerName',
            );
          }
        }
      }
      await prefs.setString(
          'last_prayer_schedule_date',
          '${now.year}-${now.month}-${now.day}');
      debugPrint(
          'scheduleAllReminders: Successfully rescheduled today\'s notifications.');
    } catch (e) {
      debugPrint('scheduleAllReminders: Error in execution: $e');
    }
  }

  /// Verifies if a new calendar day has started, resetting the prayer checkboxes.
  /// Guarantees this runs only once per calendar day.
  static Future<void> checkAndResetDailyPrayers(SharedPreferences prefs) async {
    final now = DateTime.now();
    final todayString = '${now.year}-${now.month}-${now.day}';
    final lastResetDate = prefs.getString('last_prayer_reset_date') ?? '';

    if (lastResetDate != todayString) {
      for (var prayer in _prayers) {
        await prefs.setBool(prayer, false);
      }
      await prefs.setBool('قيام الليل', false);
      await prefs.setString('last_prayer_reset_date', todayString);
      debugPrint(
          'checkAndResetDailyPrayers: Resetted prayer checklist for $todayString');
    }
  }

  /// Caches coordinates to SharedPreferences.
  static Future<void> cacheCoordinates(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('cached_latitude', lat);
    await prefs.setDouble('cached_longitude', lng);
    debugPrint('Coordinates cached: ($lat, $lng)');
  }

  /// Returns cached coordinates, if any.
  static Future<Coordinates?> getCachedCoordinates() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('cached_latitude');
    final lng = prefs.getDouble('cached_longitude');
    if (lat != null && lng != null) {
      return Coordinates(lat, lng);
    }
    return null;
  }

  /// Safely fetches location coordinates with a fallback logic.
  static Future<Coordinates?> _getCoordinates(SharedPreferences prefs) async {
    final cached = await getCachedCoordinates();
    if (cached != null) {
      return cached;
    }

    if (await Permission.location.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 5));
        await cacheCoordinates(position.latitude, position.longitude);
        return Coordinates(position.latitude, position.longitude);
      } catch (e) {
        debugPrint(
            'scheduleAllReminders: Error getting fresh position: $e. Falling back to default Cairo.');
        return Coordinates(30.0444, 31.2357); // Cairo fallback
      }
    }
    return null;
  }
}
