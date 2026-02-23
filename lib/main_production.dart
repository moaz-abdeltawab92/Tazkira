import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:quran_library/quran.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:tazkira_app/core/services/notification_service.dart';
import 'package:tazkira_app/firebase_options.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Remote Config
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    // Set default values
    await remoteConfig.setDefaults(const {
      'ios_min_version': '1.1.0',
      'ios_min_build_number': 0,
      'ios_force_update': false,
    });

    // Fetch and activate on startup
    await remoteConfig.fetchAndActivate();
  } catch (e) {
    debugPrint('Failed to initialize Remote Config: $e');
  }

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // To fix text being hidden bug in flutter_screenutil in release mode
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

  runApp(const TazkiraApp());
}

class TazkiraApp extends StatelessWidget {
  const TazkiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      ensureScreenSize: true,
      builder: (context, child) {
        return ShowCaseWidget(
          builder: (context) => MaterialApp(
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
