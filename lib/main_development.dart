import 'package:quran_library/quran.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:tazkira_app/core/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:device_preview/device_preview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  await ScreenUtil.ensureScreenSize();
  await QuranLibrary.init();

  // Initialize notification service
  await NotificationService.initialize();

  // Schedule notifications
  // For iOS, check if we need to reschedule (if last schedule was > 5 days ago)
  final prefs = await SharedPreferences.getInstance();
  final lastSchedule = prefs.getInt('last_notification_schedule') ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;
  final daysSinceLastSchedule = (now - lastSchedule) ~/ (1000 * 60 * 60 * 24);

  if (Platform.isIOS) {
    // On iOS, reschedule every 5 days to ensure notifications don't expire
    if (daysSinceLastSchedule >= 5) {
      await NotificationService.scheduleAllNotifications();
      await prefs.setInt('last_notification_schedule', now);
    }
  } else {
    // On Android, check if first time or > 25 days
    if (lastSchedule == 0 || daysSinceLastSchedule >= 25) {
      await NotificationService.scheduleAllNotifications();
      await prefs.setInt('last_notification_schedule', now);
    }
  }

  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const TazkiraApp(),
    ),
  );
}

class TazkiraApp extends StatelessWidget {
  const TazkiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ShowCaseWidget(
          builder: (context) => MaterialApp(
            // Device Preview Configuration
            useInheritedMediaQuery: true,
            locale: DevicePreview.locale(context),
            builder: DevicePreview.appBuilder,

            navigatorKey: navigatorKey,
            theme: ThemeData(
              useMaterial3: false,
            ),
            debugShowCheckedModeBanner: false,
            home: const Homepage(),
          ),
        );
      },
    );
  }
}
