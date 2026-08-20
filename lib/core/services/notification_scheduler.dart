import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:tazkira_app/core/services/notification_service.dart';
import 'package:flutter/foundation.dart';

class NotificationScheduler {
  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String channelId,
    String? payload,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    final tzNow = tz.TZDateTime.now(tz.local);

    // Skip expired notifications
    if (tzTime.isBefore(tzNow)) {
      debugPrint('Skipping notification $id: scheduled time $tzTime is in the past ($tzNow)');
      return;
    }

    try {
      await NotificationService.notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        NotificationService.getNotificationDetails(channelId, body: body),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      debugPrint('Scheduled notification $id at $tzTime');
    } catch (e) {
      debugPrint('Failed to schedule notification $id: $e');
    }
  }

  static Future<void> cancel(int id) async {
    try {
      await NotificationService.notificationsPlugin.cancel(id);
      debugPrint('Cancelled notification $id');
    } catch (e) {
      debugPrint('Failed to cancel notification $id: $e');
    }
  }
}
