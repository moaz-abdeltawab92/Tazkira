import 'package:hijri/hijri_calendar.dart';
import 'package:tazkira_app/core/utils/hijri_date_offset_helper.dart';

class IslamicSeasonHelper {
  static Future<HijriCalendar> getAdjustedHijriDate() async {
    try {
      final offset = await HijriDateOffsetHelper.getOffset();
      final now = DateTime.now();
      final adjustedDate = now.add(Duration(days: offset));
      final hijriDate = HijriCalendar.fromDate(adjustedDate);
      return hijriDate;
    } catch (e) {
      // Fallback to current date without offset if error occurs
      return HijriCalendar.fromDate(DateTime.now());
    }
  }

  /// Check if current date is in Ramadan ONLY
  /// Feature will disappear immediately after Ramadan ends
  static Future<bool> isRamadanOrGracePeriod() async {
    try {
      final hijriDate = await getAdjustedHijriDate();

      // Only show during Ramadan (month 9)
      // Feature disappears immediately when Ramadan ends
      return hijriDate.hMonth == 9;
    } catch (e) {
      // If any error occurs, default to false (hide the feature)
      // This is safer than showing it incorrectly
      return false;
    }
  }

  static Future<bool> isRamadan() async {
    try {
      final hijriDate = await getAdjustedHijriDate();
      return hijriDate.hMonth == 9;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isEidAlFitr() async {
    try {
      final hijriDate = await getAdjustedHijriDate();
      return hijriDate.hMonth == 10 && hijriDate.hDay <= 3;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getCurrentSeason() async {
    try {
      if (await isRamadan()) {
        return 'ramadan';
      } else if (await isEidAlFitr()) {
        return 'eid';
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
