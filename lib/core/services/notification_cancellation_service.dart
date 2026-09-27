import 'package:tazkira_app/core/services/notification_scheduler.dart';
import 'package:flutter/foundation.dart';

class NotificationCancellationService {
  static const int _normalStartId = 1001; // Fajr: 1001, Dhuhr: 1002, Asr: 1003, Maghrib: 1004, Isha: 1005
  static const int _smartStartId = 2001;  // Fajr: 2001, Dhuhr: 2002, Asr: 2003, Maghrib: 2004, Isha: 2005

  static final List<String> _prayers = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];

  static Future<void> cancelSmartReminderForPrayer(String prayerName) async {
    final index = _prayers.indexOf(prayerName);
    if (index == -1) return;

    final id = _smartStartId + index;
    await NotificationScheduler.cancel(id);
    debugPrint('Cancelled smart reminder for $prayerName (ID: $id)');
  }

  static Future<void> cancelNormalReminderForPrayer(String prayerName) async {
    final index = _prayers.indexOf(prayerName);
    if (index == -1) return;

    final id = _normalStartId + index;
    await NotificationScheduler.cancel(id);
    debugPrint('Cancelled normal reminder for $prayerName (ID: $id)');
  }

  static Future<void> cancelAllSmartReminders() async {
    for (int i = 0; i < 5; i++) {
      final id = _smartStartId + i;
      await NotificationScheduler.cancel(id);
    }
    debugPrint('Cancelled all smart reminders');
  }

  static Future<void> cancelAllNormalReminders() async {
    for (int i = 0; i < 5; i++) {
      final id = _normalStartId + i;
      await NotificationScheduler.cancel(id);
    }
    debugPrint('Cancelled all normal reminders');
  }
}
