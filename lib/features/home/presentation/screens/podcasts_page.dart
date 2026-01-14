import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:tazkira_app/core/services/notification_service.dart';

class PodcastsPage extends StatefulWidget {
  const PodcastsPage({super.key});

  @override
  State<PodcastsPage> createState() => _PodcastsPageState();
}

class _PodcastsPageState extends State<PodcastsPage> {
  bool _prayerRemindersEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _prayerRemindersEnabled =
          prefs.getBool('prayer_reminders_enabled') ?? false;
    });
  }

  Future<void> _togglePrayerReminders(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prayer_reminders_enabled', value);

    setState(() {
      _prayerRemindersEnabled = value;
    });

    if (value) {
      await NotificationService.schedulePrayerTimeReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تفعيل تنبيهات الصلاة',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: const Color(0xFF1B5E5E),
          ),
        );
      }
    } else {
      await NotificationService.cancelPrayerTimeReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إيقاف تنبيهات الصلاة',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 175, 197, 195),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: Stack(
            children: [
              // Background Image
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/back_ground.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Content
              SingleChildScrollView(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Settings Section at the top
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SwitchListTile(
                          value: _prayerRemindersEnabled,
                          onChanged: _togglePrayerReminders,
                          activeColor: const Color(0xFF1B5E5E),
                          title: Text(
                            'تذكير بمواقيت الصلاة',
                            style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            'تنبيه قبل كل صلاة بـ 10 دقائق',
                            style: GoogleFonts.tajawal(
                              fontSize: 12.sp,
                              color: Colors.black54,
                            ),
                          ),
                          secondary: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B5E5E).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_active_outlined,
                              color: const Color(0xFF1B5E5E),
                              size: 24.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 18.h),

                      // internal section header (matches screenshot style)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'البودكاستات والقنوات المقترحة',
                              style: GoogleFonts.cairo(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // nicer podcast cards horizontally
                      const PodcastCardWidget(),
                      SizedBox(height: 18.h),

                      // share button
                      const ShareButton(),

                      SizedBox(height: 18.h),

                      // bottom rounded contact card with circular social icons (styled like screenshot)
                      const ContactMeSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
