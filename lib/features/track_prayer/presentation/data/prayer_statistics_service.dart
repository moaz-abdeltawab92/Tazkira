import 'package:shared_preferences/shared_preferences.dart';

class PrayerStatisticsService {
  static const String _currentStreakKey = 'prayer_current_streak';
  static const String _longestStreakKey = 'prayer_longest_streak';
  static const String _lastCompleteDateKey = 'prayer_last_complete_date';
  static const String _totalDaysTrackedKey = 'prayer_total_days_tracked';
  static const String _totalPrayersCompletedKey =
      'prayer_total_prayers_completed';

  // Get current streak
  static Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentStreakKey) ?? 0;
  }

  // Get longest streak
  static Future<int> getLongestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_longestStreakKey) ?? 0;
  }

  // Get last complete date
  static Future<String?> getLastCompleteDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastCompleteDateKey);
  }

  // Get total days tracked
  static Future<int> getTotalDaysTracked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalDaysTrackedKey) ?? 0;
  }

  // Get total prayers completed
  static Future<int> getTotalPrayersCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalPrayersCompletedKey) ?? 0;
  }

  // Check if all 5 prayers are completed for today
  static Future<bool> areAllPrayersCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final prayers = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];

    for (var prayer in prayers) {
      if (!(prefs.getBool(prayer) ?? false)) {
        return false;
      }
    }
    return true;
  }

  // Update streak when all prayers are completed
  static Future<void> updateStreakIfComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    // Check if already updated today
    final lastDate = prefs.getString(_lastCompleteDateKey);
    if (lastDate == todayString) {
      return; // Already updated today
    }

    // Check if all prayers completed
    if (await areAllPrayersCompleted()) {
      final currentStreak = await getCurrentStreak();
      final longestStreak = await getLongestStreak();
      final totalDays = await getTotalDaysTracked();

      // Check if yesterday was completed
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayString =
          '${yesterday.year}-${yesterday.month}-${yesterday.day}';

      int newStreak;
      if (lastDate == yesterdayString) {
        // Continue streak
        newStreak = currentStreak + 1;
      } else if (lastDate == null || lastDate.isEmpty) {
        // First time
        newStreak = 1;
      } else {
        // Streak broken, start new
        newStreak = 1;
      }

      // Update values
      await prefs.setInt(_currentStreakKey, newStreak);
      await prefs.setString(_lastCompleteDateKey, todayString);
      await prefs.setInt(_totalDaysTrackedKey, totalDays + 1);

      // Update longest streak if needed
      if (newStreak > longestStreak) {
        await prefs.setInt(_longestStreakKey, newStreak);
      }
    }
  }

  // Increment total prayers completed
  static Future<void> incrementTotalPrayers() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getTotalPrayersCompleted();
    await prefs.setInt(_totalPrayersCompletedKey, current + 1);
  }

  // Reset streak (when a day is missed)
  static Future<void> checkAndResetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = await getLastCompleteDate();

    if (lastDate == null || lastDate.isEmpty) return;

    final today = DateTime.now();
    // Normalize to start of day
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final lastDateTime = DateTime.parse(lastDate);
    final lastDateNormalized =
        DateTime(lastDateTime.year, lastDateTime.month, lastDateTime.day);
    final difference = todayNormalized.difference(lastDateNormalized).inDays;

    // If more than 1 day passed without completion, reset streak
    if (difference > 1) {
      await prefs.setInt(_currentStreakKey, 0);
    }
  }

  // Get statistics summary
  static Future<Map<String, dynamic>> getStatisticsSummary() async {
    await checkAndResetStreak();

    return {
      'currentStreak': await getCurrentStreak(),
      'longestStreak': await getLongestStreak(),
      'lastCompleteDate': await getLastCompleteDate(),
      'totalDaysTracked': await getTotalDaysTracked(),
      'totalPrayersCompleted': await getTotalPrayersCompleted(),
    };
  }

  // Reset all statistics (for testing)
  static Future<void> resetAllStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentStreakKey);
    await prefs.remove(_longestStreakKey);
    await prefs.remove(_lastCompleteDateKey);
    await prefs.remove(_totalDaysTrackedKey);
    await prefs.remove(_totalPrayersCompletedKey);
  }
}
