import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:tazkira_app/core/services/notification_content_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tazkira_app/core/routing/route_export.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _azkarChannelId = 'azkar_reminders';
  static const String _fridayChannelId = 'friday_reminders';
  static const String _prayerChannelId = 'prayer_reminders';

  static const int _morningAzkarStartId = 10;
  static const int _eveningAzkarStartId = 20;
  static const int _generalHourlyStartId = 100;
  static const int _fridaySurahKahfStartId = 200;
  static const int _fridaySalatProphetStartId = 300;
  static const int _surahMulkId = 400;
  static const int _beforeSleepDhikrId = 410;
  static const int _prayerReminderStartId = 500;

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('tazkira_notification');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _requestPermissions();

    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    } else if (Platform.isIOS) {}
  }

  static Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    const AndroidNotificationChannel azkarChannel = AndroidNotificationChannel(
      _azkarChannelId,
      'تذكير بالأذكار',
      description: 'تذكيرات يومية بأذكار الصباح والمساء والأذكار العامة',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: false,
    );

    const AndroidNotificationChannel fridayChannel = AndroidNotificationChannel(
      _fridayChannelId,
      'تذكيرات يوم الجمعة',
      description: 'تذكيرات خاصة بيوم الجمعة (سورة الكهف والصلاة على النبي)',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: false,
    );

    const AndroidNotificationChannel prayerChannel = AndroidNotificationChannel(
      _prayerChannelId,
      'تذكير بمواقيت الصلاة',
      description: 'تنبيه صامت قبل الصلاة بـ 10 دقائق',
      importance: Importance.max,
      playSound: false,
      enableVibration: false,
    );

    await androidPlugin.createNotificationChannel(azkarChannel);
    await androidPlugin.createNotificationChannel(fridayChannel);
    await androidPlugin.createNotificationChannel(prayerChannel);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification Tapped with payload: ${response.payload}');
    if (response.payload != null) {
      if (response.payload == 'أذكار الصباح' ||
          response.payload == 'أذكار المساء') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => AzkarScreen(
              initialCategory: response.payload,
            ),
          ),
        );
      }
    }
  }

  static Future<void> scheduleAllNotifications() async {
    await _notificationsPlugin.cancelAll();

    await _scheduleMorningAzkar();

    await _scheduleEveningAzkar();

    await _scheduleHourlyNotifications();

    await _scheduleFridayNotifications();

    await _scheduleSurahMulk();

    await _scheduleBeforeSleepDhikr();

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('prayer_reminders_enabled') ?? false) {
      await schedulePrayerTimeReminders();
    }
  }

  static Future<void> _scheduleMorningAzkar() async {
    final cairo = tz.getLocation('Africa/Cairo');
    final hours = [6, 9];

    for (int i = 0; i < hours.length; i++) {
      final hour = hours[i];
      final now = tz.TZDateTime.now(cairo);
      var scheduledDate = tz.TZDateTime(
        cairo,
        now.year,
        now.month,
        now.day,
        hour,
        0,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final content = NotificationContentProvider.getRandomMorningAzkar();

      await _notificationsPlugin.zonedSchedule(
        _morningAzkarStartId + i,
        NotificationContentProvider.getMorningAzkarTitle(),
        content,
        scheduledDate,
        _getNotificationDetails(_azkarChannelId, body: content),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'أذكار الصباح',
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static Future<void> _scheduleEveningAzkar() async {
    final cairo = tz.getLocation('Africa/Cairo');
    final hours = [16, 19];

    for (int i = 0; i < hours.length; i++) {
      final hour = hours[i];
      final now = tz.TZDateTime.now(cairo);
      var scheduledDate = tz.TZDateTime(
        cairo,
        now.year,
        now.month,
        now.day,
        hour,
        0,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final content = NotificationContentProvider.getRandomEveningAzkar();

      await _notificationsPlugin.zonedSchedule(
        _eveningAzkarStartId + i,
        NotificationContentProvider.getEveningAzkarTitle(),
        content,
        scheduledDate,
        _getNotificationDetails(_azkarChannelId, body: content),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'أذكار المساء',
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static Future<void> _scheduleHourlyNotifications() async {
    final hours = List.generate(12, (index) => index * 2);

    for (int i = 0; i < hours.length; i++) {
      final hour = hours[i];
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        0,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final content = NotificationContentProvider.getRandomGeneralContent();

      await _notificationsPlugin.zonedSchedule(
        _generalHourlyStartId + i,
        NotificationContentProvider.getGeneralNotificationTitle(),
        content,
        scheduledDate,
        _getNotificationDetails(_azkarChannelId, body: content),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static Future<void> _scheduleFridayNotifications() async {
    final surahKahfHours = [9, 13, 17];

    for (int i = 0; i < surahKahfHours.length; i++) {
      await _scheduleFridayNotification(
        _fridaySurahKahfStartId + i,
        surahKahfHours[i],
        NotificationContentProvider.getFridayNotificationTitle(),
        NotificationContentProvider.getSurahKahfReminder(),
      );
    }

    final salatProphetHours = [7, 9, 11, 12, 13, 15, 17, 19, 20, 21, 22, 23];

    for (int i = 0; i < salatProphetHours.length; i++) {
      await _scheduleFridayNotification(
        _fridaySalatProphetStartId + i,
        salatProphetHours[i],
        NotificationContentProvider.getFridayNotificationTitle(),
        NotificationContentProvider.getSalatOnProphetReminder(),
      );
    }
  }

  static Future<void> _scheduleSurahMulk() async {
    final cairo = tz.getLocation('Africa/Cairo');
    final now = tz.TZDateTime.now(cairo);
    var scheduledDate = tz.TZDateTime(
      cairo,
      now.year,
      now.month,
      now.day,
      22,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final surahMulkContent = NotificationContentProvider.getSurahMulkReminder();

    await _notificationsPlugin.zonedSchedule(
      _surahMulkId,
      'تذكير سورة المُلك',
      surahMulkContent,
      scheduledDate,
      _getNotificationDetails(_azkarChannelId, body: surahMulkContent),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'سورة التبارك',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> _scheduleBeforeSleepDhikr() async {
    final cairo = tz.getLocation('Africa/Cairo');
    final now = tz.TZDateTime.now(cairo);
    var scheduledDate = tz.TZDateTime(
      cairo,
      now.year,
      now.month,
      now.day,
      0,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final beforeSleepContent =
        NotificationContentProvider.getBeforeSleepDhikr();

    await _notificationsPlugin.zonedSchedule(
      _beforeSleepDhikrId,
      'أذكار النوم',
      beforeSleepContent,
      scheduledDate,
      _getNotificationDetails(_azkarChannelId, body: beforeSleepContent),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'أذكار النوم',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> _scheduleFridayNotification(
    int id,
    int hour,
    String title,
    String body,
  ) async {
    final cairo = tz.getLocation('Africa/Cairo');
    final now = tz.TZDateTime.now(cairo);

    int daysUntilFriday = (DateTime.friday - now.weekday) % 7;
    if (daysUntilFriday == 0) {
      final scheduledTime = tz.TZDateTime(
        cairo,
        now.year,
        now.month,
        now.day,
        hour,
        0,
      );

      if (scheduledTime.isBefore(now)) {
        daysUntilFriday = 7;
      }
    }

    var scheduledDate = tz.TZDateTime(
      cairo,
      now.year,
      now.month,
      now.day + daysUntilFriday,
      hour,
      0,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _getNotificationDetails(_fridayChannelId, body: body),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static NotificationDetails _getNotificationDetails(String channelId,
      {String? body}) {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == _azkarChannelId
          ? 'تذكير بالأذكار'
          : channelId == _fridayChannelId
              ? 'تذكيرات يوم الجمعة'
              : 'تذكير بمواقيت الصلاة',
      channelDescription: channelId == _azkarChannelId
          ? 'تذكيرات يومية بالأذكار والأدعية'
          : channelId == _fridayChannelId
              ? 'تذكيرات خاصة بيوم الجمعة'
              : 'تنبيه صامت قبل الصلاة بـ 10 دقائق',
      importance: channelId == _prayerChannelId
          ? Importance.max
          : Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: channelId != _prayerChannelId,
      enableVibration: false,
      icon: 'tazkira_notification_monochrome',
      styleInformation: BigTextStyleInformation(body ?? ''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  static Future<void> schedulePrayerTimeReminders() async {
    try {
      if (await Permission.location.isDenied) {
        final status = await Permission.location.request();
        if (!status.isGranted) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final coordinates = Coordinates(position.latitude, position.longitude);
      final params = CalculationMethod.egyptian.getParameters();
      params.madhab = Madhab.shafi;

      final now = DateTime.now();

      int daysToSchedule = Platform.isAndroid ? 30 : 3;

      for (int dayOffset = 0; dayOffset < daysToSchedule; dayOffset++) {
        final date = now.add(Duration(days: dayOffset));
        final dateComponents = DateComponents(date.year, date.month, date.day);
        final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

        final prayers = [
          {'name': 'الفجر', 'time': prayerTimes.fajr},
          {'name': 'الظهر', 'time': prayerTimes.dhuhr},
          {'name': 'العصر', 'time': prayerTimes.asr},
          {'name': 'المغرب', 'time': prayerTimes.maghrib},
          {'name': 'العشاء', 'time': prayerTimes.isha},
        ];

        for (int i = 0; i < prayers.length; i++) {
          final p = prayers[i];
          final String name = p['name'] as String;
          final DateTime time = p['time'] as DateTime;

          final scheduledClientTime =
              time.subtract(const Duration(minutes: 10));
          final scheduledTime =
              tz.TZDateTime.from(scheduledClientTime, tz.local);

          if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
            continue;
          }

          int id = _prayerReminderStartId + (dayOffset * 10) + i;

          await _notificationsPlugin.zonedSchedule(
            id,
            name,
            NotificationContentProvider.getPrayerReminderText(name),
            scheduledTime,
            _getNotificationDetails(_prayerChannelId,
                body: NotificationContentProvider.getPrayerReminderText(name)),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      }

      debugPrint(
          'Prayer time reminders scheduled for next $daysToSchedule days');
    } catch (e) {
      debugPrint('Error scheduling prayer reminders: $e');
    }
  }

  static Future<void> cancelPrayerTimeReminders() async {
    for (int i = 0; i < 350; i++) {
      await _notificationsPlugin.cancel(_prayerReminderStartId + i);
    }
    debugPrint('Prayer time reminders cancelled');
  }
}
