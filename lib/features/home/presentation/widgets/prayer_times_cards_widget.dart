import 'package:tazkira_app/core/routing/route_export.dart';

class PrayerTimesCardsWidget extends StatefulWidget {
  const PrayerTimesCardsWidget({super.key});

  @override
  State<PrayerTimesCardsWidget> createState() => _PrayerTimesCardsWidgetState();
}

class _PrayerTimesCardsWidgetState extends State<PrayerTimesCardsWidget>
    with WidgetsBindingObserver {
  PrayerTimes? prayerTimes;
  bool isLoading = true;
  String? errorMessage;
  String? cityName;
  Timer? _countdownTimer;

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

  void _startCountdownTimer() {
    // Cancel any existing timer
    _countdownTimer?.cancel();

    // Create a new timer that runs every minute
    _countdownTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // Trigger rebuild to update countdown
      setState(() {});
    });
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

      // Start the countdown timer after prayer times are loaded
      _startCountdownTimer();
    } catch (e) {
      setState(() {
        errorMessage = 'حدث خطأ: ${e.toString()}';
        isLoading = false;
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
      debugPrint('Error getting city name: $e');
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

  Widget _buildPrayerCard({
    required String name,
    required DateTime time,
    required IconData icon,
    required Color color1,
    required Color color2,
  }) {
    final bool isNextPrayer = _isNextPrayer(time);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            color1.withOpacity(isNextPrayer ? 1.0 : 0.85),
            color2.withOpacity(isNextPrayer ? 1.0 : 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isNextPrayer ? 0.25 : 0.15),
            blurRadius: isNextPrayer ? 12 : 8,
            offset: Offset(0, isNextPrayer ? 5 : 3),
          ),
        ],
        border: isNextPrayer
            ? Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  name,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isNextPrayer) ...[
                  SizedBox(height: 2.h),
                  Text(
                    'الصلاة القادمة',
                    style: GoogleFonts.cairo(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(time),
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isNextPrayer) ...[
                SizedBox(height: 4.h),
                Text(
                  _getTimeRemaining(time),
                  style: GoogleFonts.cairo(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  bool _isNextPrayer(DateTime prayerTime) {
    if (prayerTimes == null) return false;

    final now = DateTime.now();
    final prayers = {
      'الفجر': prayerTimes!.fajr.toLocal(),
      'الشروق': prayerTimes!.sunrise.toLocal(),
      'الظهر': prayerTimes!.dhuhr.toLocal(),
      'العصر': prayerTimes!.asr.toLocal(),
      'المغرب': prayerTimes!.maghrib.toLocal(),
      'العشاء': prayerTimes!.isha.toLocal(),
    };

    DateTime? nextPrayerTime;
    for (var entry in prayers.entries) {
      final time = entry.value;
      if (time.isAfter(now)) {
        nextPrayerTime = time;
        break;
      }
    }

    return nextPrayerTime != null &&
        prayerTime.difference(nextPrayerTime).abs().inSeconds < 60;
  }

  String _getTimeRemaining(DateTime prayerTime) {
    final now = DateTime.now();
    final difference = prayerTime.difference(now);

    if (difference.isNegative) return '';

    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);

    if (hours > 0) {
      return 'بعد $hours س و $minutes د';
    } else if (minutes > 0) {
      return 'بعد $minutes دقيقة';
    } else {
      return 'الآن';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF5A8C8C),
        ),
      );
    }

    if (errorMessage != null) {
      // Check if error is related to permission being permanently denied
      final isPermissionDenied = errorMessage!.contains('مرفوض نهائياً') ||
          errorMessage!.contains('الإعدادات');

      return Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Icon(
              isPermissionDenied
                  ? Icons.location_off_rounded
                  : Icons.error_outline,
              color: isPermissionDenied ? const Color(0xFF5A8C8C) : Colors.red,
              size: 40.sp,
            ),
            SizedBox(height: 12.h),
            Text(
              errorMessage!,
              style: GoogleFonts.cairo(
                color:
                    isPermissionDenied ? const Color(0xFF1A1A1A) : Colors.red,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            if (isPermissionDenied)
              // Show "Open Settings" button for permission errors
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await openAppSettings();
                    },
                    icon: const Icon(Icons.settings, size: 18),
                    label: Text(
                      'فتح الإعدادات',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A8C8C),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });
                      _initializePrayerTimes();
                    },
                    child: Text(
                      'إعادة المحاولة',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF5A8C8C),
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              )
            else
              // Show only "Try Again" for other errors
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  _initializePrayerTimes();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A8C8C),
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'إعادة المحاولة',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (prayerTimes == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Location header - small
        if (cityName != null)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 12.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  cityName!,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        // Prayer Cards
        _buildPrayerCard(
          name: 'الفجر',
          time: prayerTimes!.fajr,
          icon: Icons.nightlight_round,
          color1: const Color(0xFF2D5F7F),
          color2: const Color(0xFF4A7FA0),
        ),
        _buildPrayerCard(
          name: 'الشروق',
          time: prayerTimes!.sunrise,
          icon: Icons.wb_sunny,
          color1: const Color(0xFFE59866),
          color2: const Color(0xFFF39C12),
        ),
        _buildPrayerCard(
          name: 'الظهر',
          time: prayerTimes!.dhuhr,
          icon: Icons.wb_twilight,
          color1: const Color(0xFF5A8C8C),
          color2: const Color(0xFF7CB9AD),
        ),
        _buildPrayerCard(
          name: 'العصر',
          time: prayerTimes!.asr,
          icon: Icons.wb_cloudy,
          color1: const Color(0xFFB8860B),
          color2: const Color(0xFFDAA520),
        ),
        _buildPrayerCard(
          name: 'المغرب',
          time: prayerTimes!.maghrib,
          icon: Icons.nightlight,
          color1: const Color(0xFF8E44AD),
          color2: const Color(0xFF9B59B6),
        ),
        _buildPrayerCard(
          name: 'العشاء',
          time: prayerTimes!.isha,
          icon: Icons.nights_stay,
          color1: const Color(0xFF1B3A4B),
          color2: const Color(0xFF2C5364),
        ),
      ],
    );
  }
}
