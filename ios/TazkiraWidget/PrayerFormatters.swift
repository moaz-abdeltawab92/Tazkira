//
//  PrayerFormatters.swift
//  TazkiraWidget
//
//  Pure formatting utilities shared by all widget views.
//  No network calls, no UserDefaults access, no state.
//

import Foundation

enum PrayerFormatters {

    // MARK: - Time Formatting

    /// ISO-8601 UTC → local 12-hour Arabic time string (e.g. "04:13 ص").
    ///
    /// Returns "—" for nil, empty, or unparseable input so widget views
    /// never display a blank or crash on bad data.
    static func formatTime(_ isoString: String?) -> String {
        guard
            let isoString = isoString,
            !isoString.isEmpty,
            let date = isoDate(isoString)
        else {
            return "—"
        }

        let cal = Calendar.current
        let hour24 = cal.component(.hour,   from: date)
        let minute  = cal.component(.minute, from: date)

        // Convert to 12-hour
        let hour12: Int
        if hour24 == 0 {
            hour12 = 12
        } else if hour24 > 12 {
            hour12 = hour24 - 12
        } else {
            hour12 = hour24
        }

        // Arabic AM/PM suffix matching the app's existing _formatTime() logic
        let period = hour24 >= 12 ? "م" : "ص"

        return String(format: "%02d:%02d %@", hour12, minute, period)
    }

    // MARK: - Staleness Detection

    /// Returns true when the snapshot is strictly older than 30 days.
    /// Since we precalculate 30 days of prayer times, we allow the snapshot
    /// to remain valid up to 720 hours (30 days * 24 hours).
    ///
    /// Returns false for nil, empty, or unparseable timestamps so that
    /// missing timestamps trigger the placeholder state (handled by callers)
    /// rather than the staleness indicator.
    static func isStale(_ isoTimestamp: String?) -> Bool {
        guard
            let isoTimestamp = isoTimestamp,
            !isoTimestamp.isEmpty,
            let date = isoDate(isoTimestamp)
        else {
            return false
        }

        let ageSeconds = Date().timeIntervalSince(date)
        return ageSeconds > (30 * 24 * 3600)
    }

    // MARK: - Active Dataset Resolver

    struct ActivePrayerData {
        let date: String
        let hijriDate: String
        let fajr: String
        let dhuhr: String
        let asr: String
        let maghrib: String
        let isha: String
    }

    /// Resolves the active dataset depending on the entry's date by searching in snapshot.days list first.
    static func getActiveData(snapshot: PrayerSnapshot, for date: Date) -> ActivePrayerData {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let localDateString = formatter.string(from: date)
        
        // Search in precalculated 30 days list first
        if let days = snapshot.days, let matchedDay = days.first(where: { $0.date == localDateString }) {
            return ActivePrayerData(
                date: matchedDay.date,
                hijriDate: matchedDay.hijriDate,
                fajr: matchedDay.fajr,
                dhuhr: matchedDay.dhuhr,
                asr: matchedDay.asr,
                maghrib: matchedDay.maghrib,
                isha: matchedDay.isha
            )
        }
        
        if let tomorrowDate = snapshot.tomorrowDate, localDateString == tomorrowDate {
            return ActivePrayerData(
                date: tomorrowDate,
                hijriDate: snapshot.tomorrowHijriDate ?? "",
                fajr: snapshot.tomorrowFajr ?? "",
                dhuhr: snapshot.tomorrowDhuhr ?? "",
                asr: snapshot.tomorrowAsr ?? "",
                maghrib: snapshot.tomorrowMaghrib ?? "",
                isha: snapshot.tomorrowIsha ?? ""
            )
        }
        
        return ActivePrayerData(
            date: snapshot.date ?? "",
            hijriDate: snapshot.hijriDate,
            fajr: snapshot.fajr,
            dhuhr: snapshot.dhuhr,
            asr: snapshot.asr,
            maghrib: snapshot.maghrib,
            isha: snapshot.isha
        )
    }

    // MARK: - Next Prayer Calculation

    /// Dynamically determines the next prayer by comparing the timeline date
    /// against the pre-calculated ISO strings from Flutter.
    static func determineNextPrayer(snapshot: PrayerSnapshot, date: Date) -> (String, String) {
        let active = getActiveData(snapshot: snapshot, for: date)
        let prayers: [(String, String)] = [
            ("الفجر", active.fajr),
            ("الظهر", active.dhuhr),
            ("العصر", active.asr),
            ("المغرب", active.maghrib),
            ("العشاء", active.isha)
        ]

        for (name, isoString) in prayers {
            if let prayerDate = isoDate(isoString), prayerDate > date {
                return (name, isoString)
            }
        }

        // If all active prayers have passed, the next prayer is tomorrow's Fajr
        let cal = Calendar.current
        if let tomorrow = cal.date(byAdding: .day, value: 1, to: date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone.current
            let tomorrowDateString = formatter.string(from: tomorrow)
            
            if let days = snapshot.days, let matchedTomorrow = days.first(where: { $0.date == tomorrowDateString }) {
                return ("الفجر", matchedTomorrow.fajr)
            }
        }

        // Fallback for tomorrow's Fajr legacy fields
        if let tomorrowFajr = snapshot.tomorrowFajr, let tomorrowDate = snapshot.tomorrowDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone.current
            let localDateString = formatter.string(from: date)
            
            // Only highlight tomorrow's Fajr if we aren't already on tomorrow's date
            if localDateString != tomorrowDate {
                return ("الفجر", tomorrowFajr)
            }
        }

        return ("الفجر", active.fajr)
    }

    // MARK: - Private Helpers

    /// Parses an ISO-8601 UTC date string.
    /// Supports the exact format written by Dart's DateTime.toUtc().toIso8601String():
    ///   "2025-07-14T02:13:00.000Z"
    private static func isoDate(_ string: String) -> Date? {
        // Try fractional-seconds format first (Dart default)
        if let date = isoFormatterWithFraction.date(from: string) {
            return date
        }
        // Fallback: whole-seconds format
        return isoFormatterNoFraction.date(from: string)
    }

    private static let isoFormatterWithFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoFormatterNoFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
