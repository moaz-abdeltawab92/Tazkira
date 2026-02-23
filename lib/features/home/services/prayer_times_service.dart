import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'next_prayer_info.dart';

/// Service class responsible for calculating prayer times and determining
/// the next upcoming prayer with its remaining time.
class PrayerTimesService {
  /// Calculates the next prayer information based on the provided coordinates.
  ///
  /// This method calculates today's prayer times using the adhan package,
  /// finds the next upcoming prayer, and if no prayer is left for today,
  /// it calculates tomorrow's Fajr prayer.
  ///
  /// Returns a [NextPrayerInfo] object containing the next prayer name,
  /// time, and remaining duration, or null if an error occurs.
  NextPrayerInfo? getNextPrayerInfo(Coordinates coordinates) {
    try {
      final now = DateTime.now();

      // Calculate today's prayer times
      final params = CalculationMethod.egyptian.getParameters();
      params.madhab = Madhab.shafi;

      final localDate = DateComponents(now.year, now.month, now.day);

      final todayPrayerTimes = PrayerTimes(
        coordinates,
        localDate,
        params,
      );

      final prayers = {
        'الفجر': todayPrayerTimes.fajr.toLocal(),
        'الظهر': todayPrayerTimes.dhuhr.toLocal(),
        'العصر': todayPrayerTimes.asr.toLocal(),
        'المغرب': todayPrayerTimes.maghrib.toLocal(),
        'العشاء': todayPrayerTimes.isha.toLocal(),
      };

      DateTime? nextPrayerTime;
      String? nextPrayerNameTemp;

      for (var entry in prayers.entries) {
        final prayerTime = entry.value;
        if (prayerTime.isAfter(now.add(const Duration(seconds: 30)))) {
          nextPrayerTime = prayerTime;
          nextPrayerNameTemp = entry.key;
          break;
        }
      }

      if (nextPrayerTime == null) {
        final tomorrow = now.add(const Duration(days: 1));
        final params = CalculationMethod.egyptian.getParameters();
        params.madhab = Madhab.shafi;

        try {
          final tomorrowDate = DateComponents(
            tomorrow.year,
            tomorrow.month,
            tomorrow.day,
          );

          final tomorrowPrayers = PrayerTimes(
            coordinates,
            tomorrowDate,
            params,
          );

          nextPrayerTime = tomorrowPrayers.fajr.toLocal();
          nextPrayerNameTemp = 'الفجر';
        } catch (e) {
          debugPrint('Error calculating tomorrow\'s Fajr: $e');
          return null;
        }
      }

      final difference = nextPrayerTime.difference(now);

      if (difference.isNegative) {
        return null;
      }

      return NextPrayerInfo(
        nextPrayerName: nextPrayerNameTemp!,
        nextPrayerTime: nextPrayerTime,
        remainingDuration: difference,
      );
    } catch (e) {
      debugPrint('Error in countdown update: $e');
      return null;
    }
  }
}
