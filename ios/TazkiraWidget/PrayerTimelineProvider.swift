//
//  PrayerTimelineProvider.swift
//  TazkiraWidget
//
//  Builds the WidgetKit timeline from the prayer snapshot stored in the
//  shared App Group UserDefaults by the Flutter app.
//
//  Timeline strategy:
//  - One entry per remaining obligatory prayer transition today, timed so
//    the widget re-renders exactly when the next prayer changes.
//  - One additional entry at midnight to refresh the prayer schedule for
//    the new day.
//  - .atEnd reload policy with a 5-minute post-midnight floor, so the
//    extension fetches a fresh timeline for the new day shortly after midnight.
//

import WidgetKit
import Foundation

struct PrayerTimelineProvider: TimelineProvider {

    // MARK: - TimelineProvider

    /// Placeholder shown while the widget is first loading (e.g. in the
    /// widget gallery). Uses nil snapshot → views show placeholder UI.
    func placeholder(in context: Context) -> PrayerEntry {
        PrayerEntry(date: Date(), snapshot: nil)
    }

    /// Single snapshot for the widget gallery preview. Uses real data if
    /// available, falls back to nil snapshot.
    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        completion(PrayerEntry(date: Date(), snapshot: SnapshotReader.read()))
    }

    /// Builds the full timeline of entries.
    ///
    /// Entry dates are set to each remaining prayer time today so WidgetKit
    /// re-renders the widget at the exact moment the displayed prayer changes.
    /// A midnight entry refreshes the schedule for the new day.
    /// If no snapshot is available a single entry with nil snapshot is returned
    /// and the widget retries after 60 minutes.
    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        let snapshot = SnapshotReader.read()
        let now = Date()

        guard let snapshot = snapshot else {
            // No data yet — show placeholder and retry in 60 minutes.
            let retryDate = Calendar.current.date(byAdding: .minute, value: 60, to: now)!
            let entry = PrayerEntry(date: now, snapshot: nil)
            completion(Timeline(entries: [entry], policy: .after(retryDate)))
            return
        }

        var entries: [PrayerEntry] = []

        // Build one entry per future transition (today's remaining prayers, midnight, and tomorrow's prayers).
        let transitionDates = getTransitionDates(from: snapshot, after: now)
        for date in transitionDates {
            entries.append(PrayerEntry(date: date, snapshot: snapshot))
        }

        // Always add a "now" entry so the widget renders immediately.
        entries.insert(PrayerEntry(date: now, snapshot: snapshot), at: 0)

        // Reload policy is set to 5 minutes after tomorrow's midnight since we have today + tomorrow data.
        let midnight = nextMidnight(after: now)
        let tomorrowMidnight = nextMidnight(after: midnight)
        let reloadDate = Calendar.current.date(byAdding: .minute, value: 5, to: tomorrowMidnight)!
        completion(Timeline(entries: entries, policy: .after(reloadDate)))
    }

    // MARK: - Private Helpers

    /// Gathers all future transition dates (today's remaining prayers, midnight tonight, and tomorrow's prayers)
    /// sorted in chronological order.
    private func getTransitionDates(from snapshot: PrayerSnapshot, after now: Date) -> [Date] {
        var dates: Set<Date> = []

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        
        let todayStr = formatter.string(from: now)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let tomorrowStr = formatter.string(from: tomorrow)
        
        var todayFields: [String] = []
        var tomorrowFields: [String] = []
        
        if let days = snapshot.days,
           let todayData = days.first(where: { $0.date == todayStr }),
           let tomorrowData = days.first(where: { $0.date == tomorrowStr }) {
            todayFields = [
                todayData.fajr,
                todayData.dhuhr,
                todayData.asr,
                todayData.maghrib,
                todayData.isha
            ]
            tomorrowFields = [
                tomorrowData.fajr,
                tomorrowData.dhuhr,
                tomorrowData.asr,
                tomorrowData.maghrib,
                tomorrowData.isha
            ]
        } else {
            todayFields = [
                snapshot.fajr,
                snapshot.dhuhr,
                snapshot.asr,
                snapshot.maghrib,
                snapshot.isha
            ]
            tomorrowFields = [
                snapshot.tomorrowFajr ?? "",
                snapshot.tomorrowDhuhr ?? "",
                snapshot.tomorrowAsr ?? "",
                snapshot.tomorrowMaghrib ?? "",
                snapshot.tomorrowIsha ?? ""
            ]
        }

        for field in todayFields {
            if let d = parseISO(field), d > now {
                dates.insert(d)
            }
        }

        for field in tomorrowFields {
            if !field.isEmpty, let d = parseISO(field), d > now {
                dates.insert(d)
            }
        }

        // Midnight tonight transition
        let midnight = nextMidnight(after: now)
        if midnight > now {
            dates.insert(midnight)
        }

        return Array(dates).sorted()
    }

    /// Returns the start of the next calendar day (local midnight).
    private func nextMidnight(after date: Date) -> Date {
        var components = Calendar.current.dateComponents(
            [.year, .month, .day], from: date
        )
        // Advance by one day, zero out time components → local midnight
        components.day! += 1
        components.hour   = 0
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components) ?? date.addingTimeInterval(86400)
    }

    /// Parses an ISO-8601 UTC string into a local Date.
    /// Tries fractional seconds first (Dart default), then whole seconds.
    private func parseISO(_ string: String) -> Date? {
        if let d = isoWithFraction.date(from: string) { return d }
        return isoNoFraction.date(from: string)
    }

    private let isoWithFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private let isoNoFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
