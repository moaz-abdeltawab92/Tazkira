import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:tazkira_app/features/home/services/prayer_times_service.dart';

class PrayerTimesCard extends StatefulWidget {
  const PrayerTimesCard({super.key});

  @override
  State<PrayerTimesCard> createState() => _PrayerTimesCardState();
}

class _PrayerTimesCardState extends State<PrayerTimesCard>
    with WidgetsBindingObserver {
  PrayerTimes? prayerTimes;
  bool isLoading = true;
  String? errorMessage;
  String? cityName;
  Timer? _countdownTimer;
  String _countdownText = '';
  Coordinates? _coordinates;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePrayerTimes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Restart the timer when app resumes
      _startCountdownTimer();
    }
  }

  Future<void> _initializePrayerTimes() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            errorMessage = 'يرجى السماح بالوصول للموقع';
            isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          errorMessage = 'الإذن مرفوض نهائياً. يرجى تفعيله من الإعدادات';
          isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _getCityName(position.latitude, position.longitude);

      final coordinates = Coordinates(position.latitude, position.longitude);
      _coordinates = coordinates;

      final params = CalculationMethod.egyptian.getParameters();
      params.madhab = Madhab.shafi;

      final now = DateTime.now();
      final localDate = DateComponents(now.year, now.month, now.day);

      final prayers = PrayerTimes(
        coordinates,
        localDate,
        params,
      );

      setState(() {
        prayerTimes = prayers;
        isLoading = false;
      });

      _startCountdownTimer();
    } catch (e) {
      setState(() {
        errorMessage = 'حدث خطأ: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _startCountdownTimer() {
    // Cancel any existing timer
    _countdownTimer?.cancel();

    // Initial update
    _updateCountdown();

    // Create a new timer that runs every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    if (prayerTimes == null || _coordinates == null) return;

    final prayerTimesService = PrayerTimesService();
    final nextPrayerInfo = prayerTimesService.getNextPrayerInfo(_coordinates!);

    if (nextPrayerInfo == null) {
      if (mounted) {
        setState(() {
          _countdownText = '';
        });
      }
      return;
    }

    final difference = nextPrayerInfo.remainingDuration;
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    final nextPrayerNameTemp = nextPrayerInfo.nextPrayerName;

    String countdownString;
    if (hours > 0) {
      if (minutes > 0) {
        countdownString =
            'متبقي $hours ساعة و $minutes دقيقة على صلاة $nextPrayerNameTemp';
      } else {
        final hourWord =
            hours == 1 ? 'ساعة' : (hours == 2 ? 'ساعتان' : 'ساعات');
        countdownString = 'متبقي $hours $hourWord على صلاة $nextPrayerNameTemp';
      }
    } else if (minutes > 0) {
      final minuteWord =
          minutes == 1 ? 'دقيقة' : (minutes == 2 ? 'دقيقتان' : 'دقيقة');
      countdownString =
          'متبقي $minutes $minuteWord على صلاة $nextPrayerNameTemp';
    } else {
      countdownString = 'حان الآن موعد صلاة $nextPrayerNameTemp';
    }

    if (mounted) {
      setState(() {
        _countdownText = countdownString;
      });
    }
  }

  Future<void> _getCityName(double lat, double lon) async {
    try {
      if (cityName == null || cityName == 'جاري تحديد الموقع...') {
        setState(() => cityName = 'جاري تحديد الموقع...');
      }

      final List<Placemark> placemarks =
          await placemarkFromCoordinates(lat, lon)
              .timeout(const Duration(seconds: 10));

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;

        String? location =
            (place.subLocality != null && place.subLocality!.isNotEmpty)
                ? place.subLocality
                : (place.locality != null && place.locality!.isNotEmpty)
                    ? place.locality
                    : (place.administrativeArea != null &&
                            place.administrativeArea!.isNotEmpty)
                        ? place.administrativeArea
                        : place.name;

        if (mounted) {
          setState(() {
            cityName = (location != null && location.isNotEmpty)
                ? location
                : 'موقعك الحالي';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          cityName ??= 'موقعك الحالي';
        });
      }
    }
  }

  String _formatTime(DateTime time) {
    final localTime = time.toLocal();
    final hour = localTime.hour;
    final minute = localTime.minute;

    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final period = hour >= 12 ? 'م' : 'ص';

    return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFF1B5E5E).withOpacity(0.9),
            const Color(0xFF2D8B8B).withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isLoading
          ? _buildLoadingState()
          : errorMessage != null
              ? _buildErrorState()
              : _buildPrayerTimesContent(),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: double.infinity,
        height: 150.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, color: Colors.white, size: 40.sp),
        SizedBox(height: 8.h),
        Text(
          errorMessage!,
          style: GoogleFonts.tajawal(
            color: Colors.white,
            fontSize: 14.sp,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12.h),
        ElevatedButton(
          onPressed: () {
            setState(() {
              isLoading = true;
              errorMessage = null;
            });
            _initializePrayerTimes();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1B5E5E),
          ),
          child: Text(
            'إعادة المحاولة',
            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerTimesContent() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, color: Colors.white, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'مواقيت الصلاة',
              style: GoogleFonts.tajawal(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          cityName ?? 'موقعك الحالي',
          style: GoogleFonts.tajawal(
            color: Colors.white70,
            fontSize: 12.sp,
          ),
        ),
        if (_countdownText.isNotEmpty) ...[
          SizedBox(height: 16.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  _countdownText,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPrayerTime('الفجر', prayerTimes!.fajr),
            _buildPrayerTime('الشروق', prayerTimes!.sunrise),
            _buildPrayerTime('الظهر', prayerTimes!.dhuhr),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPrayerTime('العصر', prayerTimes!.asr),
            _buildPrayerTime('المغرب', prayerTimes!.maghrib),
            _buildPrayerTime('العشاء', prayerTimes!.isha),
          ],
        ),
      ],
    );
  }

  Widget _buildPrayerTime(String name, DateTime time) {
    return Column(
      children: [
        Text(
          name,
          style: GoogleFonts.tajawal(
            color: Colors.white,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          _formatTime(time),
          style: GoogleFonts.tajawal(
            color: Colors.white70,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }
}
