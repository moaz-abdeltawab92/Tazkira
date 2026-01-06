import 'package:quran_library/quran.dart';
import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:tazkira_app/core/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  await ScreenUtil.ensureScreenSize();
  await QuranLibrary.init();

  // Initialize notification service
  await NotificationService.initialize();
  await NotificationService.scheduleAllNotifications();

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
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          theme: ThemeData(
            useMaterial3: false,
          ),
          debugShowCheckedModeBanner: false,
          home: const Homepage(),
        );
      },
    );
  }
}
