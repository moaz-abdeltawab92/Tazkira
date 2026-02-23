import 'package:tazkira_app/core/routing/route_export.dart';

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  Map<String, DateTime>? prayerTimes;
  String? cityName;

  @override
  void initState() {
    super.initState();
    getPrayerTimes();
  }

  Future<void> getPrayerTimes() async {
    try {
      // 1) Get user location
      Position position = await _getUserLocation();

      final myCoordinates = Coordinates(position.latitude, position.longitude);

      // 2) Get city name
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      cityName =
          placemarks.first.locality ?? placemarks.first.administrativeArea;

      // 3) Define Calculation method
      final params = CalculationMethod.egyptian.getParameters();
      params.madhab = Madhab.shafi;

      // Important: use UTC for today
      final date = DateComponents.from(DateTime.now().toUtc());

      // 4) Calculate prayer times
      final times = PrayerTimes(myCoordinates, date, params);

      setState(() {
        prayerTimes = {
          "Fajr": times.fajr,
          "Sunrise": times.sunrise,
          "Dhuhr": times.dhuhr,
          "Asr": times.asr,
          "Maghrib": times.maghrib,
          "Isha": times.isha,
        };
      });
    } catch (e) {
      debugPrint('Prayer Times Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: const Color(0xFF2A6B5C),
              content: Text('تعذر جلب أوقات الصلاة. يرجى التحقق من موقعك.',
                  style: GoogleFonts.cairo(fontSize: 14.sp))),
        );
      }
    }
  }

  Future<Position> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _showLocationServicesDialog();
      }
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showPermissionDeniedDialog();
      }
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void _showLocationServicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'خدمة الموقع متوقفة',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'لحساب أوقات الصلاة بدقة، يرجى تفعيل خدمة الموقع (GPS) من إعدادات الجهاز.',
          style: GoogleFonts.cairo(fontSize: 16.sp),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'حسناً',
              style: GoogleFonts.cairo(
                color: const Color(0xFF2A6B5C),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'صلاحية الموقع مرفوضة',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'لاستخدام ميزة أوقات الصلاة، يجب السماح للتطبيق بالوصول إلى موقعك.\n\nيرجى فتح إعدادات التطبيق والسماح بصلاحية الموقع.',
          style: GoogleFonts.cairo(fontSize: 16.sp, height: 1.6),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Permission.location.request();
              // Try to open app settings
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A6B5C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'فتح الإعدادات',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (prayerTimes == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Prayer Times")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cityName != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                " $cityName",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: ListView(
              children: prayerTimes!.entries.map((entry) {
                return ListTile(
                  title: Text(entry.key),
                  trailing: Text(DateFormat.jm().format(entry.value.toLocal())),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
