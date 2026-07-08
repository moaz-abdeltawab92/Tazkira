import 'dart:convert';

/// Immutable snapshot of the current prayer schedule, serialised for
/// delivery to native Home Screen widgets (iOS WidgetKit / Android Glance).
///
/// Design rules:
/// - Contains ONLY the five obligatory prayers — sunrise is excluded.
/// - Does NOT contain GPS coordinates or hijri offset; those are internal.
/// - [snapshotTimestamp] is excluded from [contentEquals] so that two
///   snapshots with identical display data are considered equal, preventing
///   unnecessary widget reloads.
class PrayerDataSnapshot {
  /// Fajr prayer time — ISO-8601 UTC string.
  final String fajr;

  /// Dhuhr prayer time — ISO-8601 UTC string.
  final String dhuhr;

  /// Asr prayer time — ISO-8601 UTC string.
  final String asr;

  /// Maghrib prayer time — ISO-8601 UTC string.
  final String maghrib;

  /// Isha prayer time — ISO-8601 UTC string.
  final String isha;

  /// Arabic name of the next upcoming prayer (e.g. "المغرب").
  final String nextPrayerName;

  /// Next prayer time — ISO-8601 UTC string.
  final String nextPrayerTime;

  /// Formatted Hijri date string (e.g. "18 محرم 1447 هـ").
  final String hijriDate;

  /// ISO-8601 UTC timestamp of when this snapshot was built.
  final String snapshotTimestamp;

  const PrayerDataSnapshot({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.nextPrayerName,
    required this.nextPrayerTime,
    required this.hijriDate,
    required this.snapshotTimestamp,
  });

  // ---------------------------------------------------------------------------
  // Factory constructors
  // ---------------------------------------------------------------------------

  /// Returns an empty/invalid snapshot used as the initial value for
  /// change-detection in [WidgetDataService].
  factory PrayerDataSnapshot.empty() {
    return const PrayerDataSnapshot(
      fajr: '',
      dhuhr: '',
      asr: '',
      maghrib: '',
      isha: '',
      nextPrayerName: '',
      nextPrayerTime: '',
      hijriDate: '',
      snapshotTimestamp: '',
    );
  }

  /// Parses a [PrayerDataSnapshot] from a JSON map.
  ///
  /// Unknown extra keys are silently ignored.
  /// Returns null if any required field is absent or null.
  static PrayerDataSnapshot? fromJson(Map<String, dynamic> json) {
    try {
      final fajr = json['fajr'] as String?;
      final dhuhr = json['dhuhr'] as String?;
      final asr = json['asr'] as String?;
      final maghrib = json['maghrib'] as String?;
      final isha = json['isha'] as String?;
      final nextPrayerName = json['nextPrayerName'] as String?;
      final nextPrayerTime = json['nextPrayerTime'] as String?;
      final hijriDate = json['hijriDate'] as String?;
      final snapshotTimestamp = json['snapshotTimestamp'] as String?;

      if (fajr == null ||
          dhuhr == null ||
          asr == null ||
          maghrib == null ||
          isha == null ||
          nextPrayerName == null ||
          nextPrayerTime == null ||
          hijriDate == null ||
          snapshotTimestamp == null) {
        return null;
      }

      return PrayerDataSnapshot(
        fajr: fajr,
        dhuhr: dhuhr,
        asr: asr,
        maghrib: maghrib,
        isha: isha,
        nextPrayerName: nextPrayerName,
        nextPrayerTime: nextPrayerTime,
        hijriDate: hijriDate,
        snapshotTimestamp: snapshotTimestamp,
      );
    } catch (_) {
      return null;
    }
  }

  /// Parses a [PrayerDataSnapshot] from a JSON-encoded string.
  /// Returns null if the string is not valid JSON or fields are missing.
  static PrayerDataSnapshot? fromJsonString(String jsonString) {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  /// Serialises this snapshot to a JSON map.
  ///
  /// Intentionally excludes: sunrise, latitude, longitude, hijriOffset.
  Map<String, dynamic> toJson() {
    return {
      'fajr': fajr,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
      'nextPrayerName': nextPrayerName,
      'nextPrayerTime': nextPrayerTime,
      'hijriDate': hijriDate,
      'snapshotTimestamp': snapshotTimestamp,
    };
  }

  /// Serialises this snapshot to a JSON string.
  String toJsonString() => jsonEncode(toJson());

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Returns true when all five prayer time fields and [nextPrayerName] are
  /// non-empty — i.e. the snapshot carries enough data to be displayed.
  bool isValid() {
    return fajr.isNotEmpty &&
        dhuhr.isNotEmpty &&
        asr.isNotEmpty &&
        maghrib.isNotEmpty &&
        isha.isNotEmpty &&
        nextPrayerName.isNotEmpty &&
        nextPrayerTime.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // Change detection
  // ---------------------------------------------------------------------------

  /// Returns true when all display-relevant fields of [other] are identical
  /// to this snapshot. [snapshotTimestamp] is intentionally excluded so that
  /// a freshly-built snapshot with the same prayer data does not trigger an
  /// unnecessary widget reload.
  bool contentEquals(PrayerDataSnapshot other) {
    return fajr == other.fajr &&
        dhuhr == other.dhuhr &&
        asr == other.asr &&
        maghrib == other.maghrib &&
        isha == other.isha &&
        nextPrayerName == other.nextPrayerName &&
        nextPrayerTime == other.nextPrayerTime &&
        hijriDate == other.hijriDate;
  }

  @override
  String toString() =>
      'PrayerDataSnapshot(next: $nextPrayerName @ $nextPrayerTime, hijri: $hijriDate)';
}
