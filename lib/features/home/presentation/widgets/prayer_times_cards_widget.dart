import 'package:tazkira_app/core/routing/route_export.dart';
import 'package:tazkira_app/core/models/prayer_data_snapshot.dart';
import 'package:tazkira_app/core/services/widget_data_service.dart';
import 'package:tazkira_app/core/utils/islamic_season_helper.dart'
    as season_helper;
import 'package:hijri/hijri_calendar.dart';
import 'package:tazkira_app/core/utils/hijri_date_offset_helper.dart';

class PrayerTimesCardsWidget extends StatefulWidget {
  const PrayerTimesCardsWidget({super.key});

  @override
  State<PrayerTimesCardsWidget> createState() => _PrayerTimesCardsWidgetState();
}

class _PrayerTimesCardsWidgetState extends State<PrayerTimesCardsWidget>
    with WidgetsBindingObserver {
  PrayerTimes? prayerTimes;
  Coordinates? _currentCoordinates;
  bool isLoading = true;
  String? errorMessage;
  String? cityName;
  Timer? _countdownTimer;

  /// Cached Hijri date string refreshed asynchronously on each timer tick.
  /// Stored here so the widget snapshot can include it without blocking the UI.
  String _cachedHijriDate = '';

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
      // Re-publish snapshot when the app returns to foreground so widgets
      // reflect any changes that occurred while the app was in the background.
      _publishWidgetSnapshot();
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
      // Publish widget snapshot with already-calculated prayer data.
      // Runs fire-and-forget; does not block the UI or introduce new timers.
      _publishWidgetSnapshot();
    });
  }

  /// Builds a [PrayerDataSnapshot] from already-available [prayerTimes] and
  /// publishes it to native widgets via [WidgetDataService].
  ///
  /// This method:
  /// - Does NOT calculate prayer times (reuses [prayerTimes] computed by
  ///   [_initializePrayerTimes]).
  /// - Does NOT perform GPS or location work.
  /// - Does NOT register observers or start timers.
  /// - Awaits the Hijri date before building the snapshot so [hijriDate] is
  ///   never empty on first publish (fixes async race condition).
  ///
  /// ### Midnight rollover (Issue A)
  /// Detects when the cached [prayerTimes] is from a previous calendar day
  /// and triggers a fresh calculation before publishing. This handles the case
  /// where the app process stays alive across midnight — the 60‑second timer
  /// or an app‑resume event eventually calls this method, the stale date is
  /// detected, and [_initializePrayerTimes] recalculates for the new day.
  ///
  /// ### Cold start after midnight (Issue B — architecture limitation)
  /// If the app process is killed overnight, no snapshot is published until
  /// the user opens the app again (which triggers [initState] →
  /// [_initializePrayerTimes]). This is an inherent architectural limitation:
  /// fixing it would require native background scheduling (e.g. WorkManager,
  /// AlarmManager, a foreground service, or a background Flutter isolate),
  /// all of which are excluded by the current architecture constraints.
  Future<void> _publishWidgetSnapshot() async {
    final pt = prayerTimes;
    final coords = pt?.coordinates ?? _currentCoordinates;
    if (pt == null || coords == null) return; // Prayer data or coordinates not yet available — skip silently.

    // Issue A: midnight rollover — if the cached prayer times are from a
    // previous day, recalculate before publishing.  This guard is cheap
    // (no GPS, no network) and fires at most once per day.
    final now = DateTime.now();
    final fajrLocal = pt.fajr.toLocal();
    if (fajrLocal.year != now.year ||
        fajrLocal.month != now.month ||
        fajrLocal.day != now.day) {
      debugPrint('[Widget] Midnight rollover detected — recalculating prayer times for the new day');
      await _initializePrayerTimes();
      return; // _initializePrayerTimes already called _publishWidgetSnapshot on success.
    }

    final todayDateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowDateStr = "${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";

    // Calculate tomorrow's prayer times falkially
    final tomorrowParams = CalculationMethod.egyptian.getParameters();
    tomorrowParams.madhab = Madhab.shafi;
    final tomorrowDate = DateComponents(tomorrow.year, tomorrow.month, tomorrow.day);
    final tomorrowPrayers = PrayerTimes(coords, tomorrowDate, tomorrowParams);

    String todayHijriStr = _cachedHijriDate;
    String tomorrowHijriStr = '';

    // Await the Hijri date so the snapshot is never published with an empty
    // hijriDate. Uses the same IslamicSeasonHelper already used by HijriDateCard.
    try {
      final offset = await HijriDateOffsetHelper.getOffset().catchError((_) => 0);
      final todayAdjusted = now.add(Duration(days: offset));
      final tomorrowAdjusted = todayAdjusted.add(const Duration(days: 1));
      
      final todayHijri = HijriCalendar.fromDate(todayAdjusted);
      final tomorrowHijri = HijriCalendar.fromDate(tomorrowAdjusted);
      
      const arabicMonths = [
        'محرم',
        'صفر',
        'ربيع الأول',
        'ربيع الآخر',
        'جمادى الأولى',
        'جمادى الآخرة',
        'رجب',
        'شعبان',
        'رمضان',
        'شوال',
        'ذو القعدة',
        'ذو الحجة',
      ];
      
      todayHijriStr =
          '${todayHijri.hDay} ${arabicMonths[todayHijri.hMonth - 1]} ${todayHijri.hYear} هـ';
      tomorrowHijriStr =
          '${tomorrowHijri.hDay} ${arabicMonths[tomorrowHijri.hMonth - 1]} ${tomorrowHijri.hYear} هـ';
      _cachedHijriDate = todayHijriStr;
    } catch (_) {
      // Keep previously cached value on error.
    }

    // Determine next obligatory prayer from already-available data.
    // PrayerTimesService.getNextPrayerInfo() cannot be reused here because it
    // requires Coordinates and recalculates PrayerTimes internally, violating
    // the no-recalculation rule. _determineNextPrayer() reads directly from
    // the already-calculated [prayerTimes] object.
    final nextPrayer = _determineNextPrayer(pt);

    final snapshot = PrayerDataSnapshot(
      date: todayDateStr,
      fajr: pt.fajr.toUtc().toIso8601String(),
      dhuhr: pt.dhuhr.toUtc().toIso8601String(),
      asr: pt.asr.toUtc().toIso8601String(),
      maghrib: pt.maghrib.toUtc().toIso8601String(),
      isha: pt.isha.toUtc().toIso8601String(),
      hijriDate: todayHijriStr,
      tomorrowDate: tomorrowDateStr,
      tomorrowFajr: tomorrowPrayers.fajr.toUtc().toIso8601String(),
      tomorrowDhuhr: tomorrowPrayers.dhuhr.toUtc().toIso8601String(),
      tomorrowAsr: tomorrowPrayers.asr.toUtc().toIso8601String(),
      tomorrowMaghrib: tomorrowPrayers.maghrib.toUtc().toIso8601String(),
      tomorrowIsha: tomorrowPrayers.isha.toUtc().toIso8601String(),
      tomorrowHijriDate: tomorrowHijriStr,
      nextPrayerName: nextPrayer.key,
      nextPrayerTime: nextPrayer.value.toUtc().toIso8601String(),
      snapshotTimestamp: DateTime.now().toUtc().toIso8601String(),
    );

    await WidgetDataService.instance.publishSnapshot(snapshot);
  }

  /// Determines the next upcoming obligatory prayer from an already-calculated
  /// [PrayerTimes] object. Returns a [MapEntry] of (Arabic name, local DateTime).
  ///
  /// Exists to avoid duplicating the next-prayer selection logic between
  /// [_publishWidgetSnapshot] and [build]. Reads only from [pt] — no
  /// recalculation, no GPS, no adhan calls.
  ///
  /// Note: [PrayerTimesService.getNextPrayerInfo] was considered but cannot be
  /// reused here because it requires [Coordinates] and recalculates [PrayerTimes]
  /// internally from scratch.
  MapEntry<String, DateTime> _determineNextPrayer(PrayerTimes pt) {
    final now = DateTime.now();
    final obligatoryPrayers = <String, DateTime>{
      'الفجر': pt.fajr.toLocal(),
      'الظهر': pt.dhuhr.toLocal(),
      'العصر': pt.asr.toLocal(),
      'المغرب': pt.maghrib.toLocal(),
      'العشاء': pt.isha.toLocal(),
    };

    for (final entry in obligatoryPrayers.entries) {
      if (entry.value.isAfter(now)) {
        return entry;
      }
    }

    // All five prayers today have passed — next is Fajr tomorrow.
    return MapEntry('الفجر', pt.fajr.toLocal().add(const Duration(days: 1)));
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
      _currentCoordinates = coordinates;

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
      // Publish an initial snapshot now that prayer data is available.
      _publishWidgetSnapshot();
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
      width: 100.w,
      margin: EdgeInsets.only(left: 8.w, top: 4.h, bottom: 4.h),
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color1.withValues(alpha: isNextPrayer ? 1.0 : 0.6),
            color2.withValues(alpha: isNextPrayer ? 1.0 : 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: color2.withValues(alpha: isNextPrayer ? 0.3 : 0.05),
            blurRadius: isNextPrayer ? 12 : 4,
            offset: Offset(0, isNextPrayer ? 6 : 2),
          ),
        ],
        border: isNextPrayer
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 2,
              )
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            name,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _formatTime(time),
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
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

    DateTime? nextTime;
    String nextName = '';
    final now = DateTime.now();
    final prayersMap = {
      'الفجر': prayerTimes!.fajr.toLocal(),
      'الشروق': prayerTimes!.sunrise.toLocal(),
      'الظهر': prayerTimes!.dhuhr.toLocal(),
      'العصر': prayerTimes!.asr.toLocal(),
      'المغرب': prayerTimes!.maghrib.toLocal(),
      'العشاء': prayerTimes!.isha.toLocal(),
    };

    for (var entry in prayersMap.entries) {
      if (entry.value.isAfter(now)) {
        nextTime = entry.value;
        nextName = entry.key;
        break;
      }
    }

    // Fallback if all prayers today have passed (next prayer is Fajr tomorrow)
    if (nextTime == null) {
      nextTime = prayerTimes!.fajr.toLocal().add(const Duration(days: 1));
      nextName = 'الفجر';
    }

    return Column(
      children: [
        // Location header
        if (cityName != null)
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 14.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  cityName!,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        // Next Prayer Info Banner
        Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        color: Colors.white, size: 18.sp),
                    SizedBox(width: 6.w),
                    Text(
                      _getTimeRemaining(nextTime),
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'الصلاة القادمة',
                    style: GoogleFonts.cairo(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12.sp,
                    ),
                  ),
                  Text(
                    nextName,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Horizontal Prayer Cards
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildPrayerCard(
                name: 'العشاء',
                time: prayerTimes!.isha,
                icon: Icons.nights_stay,
                color1: const Color(0xFF1B3A4B),
                color2: const Color(0xFF2C5364),
              ),
              _buildPrayerCard(
                name: 'المغرب',
                time: prayerTimes!.maghrib,
                icon: Icons.nightlight,
                color1: const Color(0xFF8E44AD),
                color2: const Color(0xFF9B59B6),
              ),
              _buildPrayerCard(
                name: 'العصر',
                time: prayerTimes!.asr,
                icon: Icons.wb_cloudy,
                color1: const Color(0xFFB8860B),
                color2: const Color(0xFFDAA520),
              ),
              _buildPrayerCard(
                name: 'الظهر',
                time: prayerTimes!.dhuhr,
                icon: Icons.wb_twilight,
                color1: const Color(0xFF5A8C8C),
                color2: const Color(0xFF7CB9AD),
              ),
              _buildPrayerCard(
                name: 'الشروق',
                time: prayerTimes!.sunrise,
                icon: Icons.wb_sunny,
                color1: const Color(0xFFE59866),
                color2: const Color(0xFFF39C12),
              ),
              _buildPrayerCard(
                name: 'الفجر',
                time: prayerTimes!.fajr,
                icon: Icons.nightlight_round,
                color1: const Color(0xFF2D5F7F),
                color2: const Color(0xFF4A7FA0),
              ),
            ]
                .reversed
                .toList(), // Reversed so Fajr is on the right side for RTL UI
          ),
        ),
      ],
    );
  }
}
