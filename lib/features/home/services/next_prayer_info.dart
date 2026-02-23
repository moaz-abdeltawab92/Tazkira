/// Model class representing information about the next upcoming prayer.
class NextPrayerInfo {
  /// Name of the next prayer
  final String nextPrayerName;

  /// Time when the next prayer is scheduled
  final DateTime nextPrayerTime;

  /// Duration remaining until the next prayer
  final Duration remainingDuration;

  const NextPrayerInfo({
    required this.nextPrayerName,
    required this.nextPrayerTime,
    required this.remainingDuration,
  });
}
