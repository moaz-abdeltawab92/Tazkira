import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:tazkira_app/core/services/notification_service.dart';
import 'package:tazkira_app/core/utils/hijri_date_offset_helper.dart';

class PodcastsPage extends StatefulWidget {
  const PodcastsPage({super.key});

  @override
  State<PodcastsPage> createState() => _PodcastsPageState();
}

class _PodcastsPageState extends State<PodcastsPage> {
  bool _prayerRemindersEnabled = false;
  bool _lastThirdNightEnabled = false;
  int _hijriDateOffset = 0;
  int _initialHijriDateOffset = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final offset = await HijriDateOffsetHelper.getOffset();
    setState(() {
      _prayerRemindersEnabled =
          prefs.getBool('prayer_reminders_enabled') ?? false;
      _lastThirdNightEnabled =
          prefs.getBool('last_third_night_enabled') ?? false;
      _hijriDateOffset = offset;
      _initialHijriDateOffset = offset;
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
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تفعيل تنبيهات الصلاة',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: const Color(0xFF1B5E5E),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      await NotificationService.cancelPrayerTimeReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إيقاف تنبيهات الصلاة',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _toggleLastThirdNight(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('last_third_night_enabled', value);

    setState(() {
      _lastThirdNightEnabled = value;
    });

    if (value) {
      await NotificationService.scheduleLastThirdOfNightReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تفعيل تنبيه الثلث الأخير من الليل',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: const Color(0xFF1B5E5E),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      await NotificationService.cancelLastThirdOfNightReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إيقاف تنبيه الثلث الأخير من الليل',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _updateHijriOffset(int newOffset) async {
    await HijriDateOffsetHelper.setOffset(newOffset);
    setState(() {
      _hijriDateOffset = newOffset;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تعديل التاريخ الهجري بمقدار ${newOffset >= 0 ? '+' : ''}$newOffset يوم',
            style: GoogleFonts.tajawal(),
          ),
          backgroundColor: const Color(0xFF1B5E5E),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          ScaffoldMessenger.of(context).clearSnackBars();
          final settingsChanged = _hijriDateOffset != _initialHijriDateOffset;
          Navigator.of(context).pop(settingsChanged);
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 175, 197, 195),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                final settingsChanged =
                    _hijriDateOffset != _initialHijriDateOffset;
                Navigator.of(context).pop(settingsChanged);
              },
            ),
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
                        child: Column(
                          children: [
                            SwitchListTile(
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
                                'تنبيه قبل موعد كل صلاة بـ 15 دقيقة',
                                style: GoogleFonts.tajawal(
                                  fontSize: 12.sp,
                                  color: Colors.black54,
                                ),
                              ),
                              secondary: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF1B5E5E).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.notifications_active_outlined,
                                  color: const Color(0xFF1B5E5E),
                                  size: 24.sp,
                                ),
                              ),
                            ),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: Colors.grey.withOpacity(0.2),
                            ),
                            SwitchListTile(
                              value: _lastThirdNightEnabled,
                              onChanged: _toggleLastThirdNight,
                              activeColor: const Color(0xFF1B5E5E),
                              title: Text(
                                'تذكير بالثلث الأخير من الليل',
                                style: GoogleFonts.tajawal(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                'تنبيه عند بداية الثلث الاخير من الليل لقيام الليل',
                                style: GoogleFonts.tajawal(
                                  fontSize: 12.sp,
                                  color: Colors.black54,
                                ),
                              ),
                              secondary: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF1B5E5E).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.nightlight_round,
                                  color: const Color(0xFF1B5E5E),
                                  size: 24.sp,
                                ),
                              ),
                            ),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: Colors.grey.withOpacity(0.2),
                            ),
                            // Hijri Date Adjustment Section
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 16.h,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1B5E5E)
                                              .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.calendar_today,
                                          color: const Color(0xFF1B5E5E),
                                          size: 24.sp,
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'تعديل التاريخ الهجري',
                                              style: GoogleFonts.tajawal(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.sp,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              'اضبط التاريخ حسب بلدك (±2 يوم)',
                                              style: GoogleFonts.tajawal(
                                                fontSize: 12.sp,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16.h),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      for (int i = -2; i <= 2; i++)
                                        Flexible(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 2.w),
                                            child: InkWell(
                                              onTap: () =>
                                                  _updateHijriOffset(i),
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              child: Container(
                                                width: 52.w,
                                                height: 52.h,
                                                constraints: BoxConstraints(
                                                  maxWidth: 60.w,
                                                  minWidth: 40.w,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _hijriDateOffset == i
                                                      ? const Color(0xFF1B5E5E)
                                                      : Colors.grey
                                                          .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.r),
                                                  border: Border.all(
                                                    color: _hijriDateOffset == i
                                                        ? const Color(
                                                            0xFF1B5E5E)
                                                        : Colors.transparent,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    i >= 0 ? '+$i' : '$i',
                                                    style: GoogleFonts.tajawal(
                                                      fontSize: 16.sp,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          _hijriDateOffset == i
                                                              ? Colors.white
                                                              : Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  Center(
                                    child: Text(
                                      'القيمة الحالية: ${_hijriDateOffset >= 0 ? '+' : ''}$_hijriDateOffset يوم',
                                      style: GoogleFonts.tajawal(
                                        fontSize: 13.sp,
                                        color: const Color(0xFF1B5E5E),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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

                      SizedBox(height: 12.h),

                      // rate app button
                      const RateAppButton(),

                      SizedBox(height: 18.h),

                      // bottom rounded contact card with circular social icons (styled like screenshot)
                      const ContactMeSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
