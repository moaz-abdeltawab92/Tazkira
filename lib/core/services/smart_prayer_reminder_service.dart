import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tazkira_app/core/services/notification_scheduler.dart';
import 'package:tazkira_app/core/services/notification_cancellation_service.dart';
import 'package:tazkira_app/core/services/prayer_reminder_scheduler.dart';
import 'package:flutter/foundation.dart';

class SmartPrayerReminderService {
  static const int _normalStartId = 1001; // Fajr: 1001, Dhuhr: 1002, Asr: 1003, Maghrib: 1004, Isha: 1005
  static const int _smartStartId = 2001;  // Fajr: 2001, Dhuhr: 2002, Asr: 2003, Maghrib: 2004, Isha: 2005
  static const String _prayerChannelId = 'prayer_reminders';
  static final List<String> _prayers = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];

  /// Handles when a prayer completion status is toggled in the UI.
  /// Executes lightweight scheduling adjustments offline using cached coordinates.
  static Future<void> onPrayerStatusChanged(String prayerName, bool isCompleted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool prayerRemindersEnabled = prefs.getBool('prayer_reminders_enabled') ?? false;
      final bool smartRemindersEnabled = prefs.getBool('smart_prayer_reminders_enabled') ?? false;

      final index = _prayers.indexOf(prayerName);
      if (index == -1) return;

      final int smartId = _smartStartId + index; // Today's smart reminder ID

      if (isCompleted) {
        // 1. Cancel today's Smart Reminder immediately
        await NotificationScheduler.cancel(smartId);

        // 2. If both normal and smart reminders are enabled, schedule the upcoming prayer's normal reminder
        if (prayerRemindersEnabled && smartRemindersEnabled && index < 4) {
          final nextPrayerName = _prayers[index + 1];
          final nextNormalId = _normalStartId + (index + 1); // Today's next prayer normal reminder ID

          final coordinates = await PrayerReminderScheduler.getCachedCoordinates();
          if (coordinates != null) {
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

            final DateTime nextTime = prayerDateTimes[index + 1];
            final scheduledClientTime = nextTime.subtract(const Duration(minutes: 15));

            await NotificationScheduler.schedule(
              id: nextNormalId,
              title: nextPrayerName,
              body: 'تبقّى 15 دقيقة على صلاة $nextPrayerName ',
              scheduledTime: scheduledClientTime,
              channelId: _prayerChannelId,
              payload: 'prayer_$nextPrayerName',
            );
          }
        }
      } else {
        // If unchecked (marked NOT completed)
        // 1. Cancel the next prayer's normal reminder (if smart and normal are enabled)
        if (prayerRemindersEnabled && smartRemindersEnabled && index < 4) {
          final nextNormalId = _normalStartId + (index + 1);
          await NotificationScheduler.cancel(nextNormalId);
        }

        // 2. Schedule today's Smart Reminder
        if (smartRemindersEnabled) {
          final coordinates = await PrayerReminderScheduler.getCachedCoordinates();
          if (coordinates != null) {
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

            DateTime? scheduledSmartTime;
            String title = 'لسه مصلتش $prayerName؟';
            String body = '';

            switch (index) {
              case 0:
                scheduledSmartTime = prayerDateTimes[1].subtract(const Duration(minutes: 30));
                body = 'اقترب أذان الظهر.';
                break;
              case 1:
                scheduledSmartTime = prayerDateTimes[2].subtract(const Duration(minutes: 30));
                body = 'اقترب أذان العصر.';
                break;
              case 2:
                scheduledSmartTime = prayerDateTimes[3].subtract(const Duration(minutes: 30));
                body = 'اقترب أذان المغرب.';
                break;
              case 3:
                scheduledSmartTime = prayerDateTimes[4].subtract(const Duration(minutes: 30));
                body = 'اقترب أذان العشاء.';
                break;
              case 4:
                scheduledSmartTime = prayerDateTimes[4].add(const Duration(hours: 2));
                body = 'متنساش تصليها قبل ما تنام.';
                break;
            }

            if (scheduledSmartTime != null) {
              await NotificationScheduler.schedule(
                id: smartId,
                title: title,
                body: body,
                scheduledTime: scheduledSmartTime,
                channelId: _prayerChannelId,
                payload: 'smart_prayer_$prayerName',
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('SmartPrayerReminderService.onPrayerStatusChanged: Error: $e');
    }
  }

  /// Handles when smart reminders setting is disabled.
  /// Immediately cancels all smart reminders while leaving normal reminders untouched.
  static Future<void> onSmartRemindersDisabled() async {
    await NotificationCancellationService.cancelAllSmartReminders();
    debugPrint('SmartPrayerReminderService.onSmartRemindersDisabled: Cancelled all smart reminders.');
  }
}
