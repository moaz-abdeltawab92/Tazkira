//
//  SnapshotReader.swift
//  TazkiraWidget
//
//  Reads the prayer data snapshot written by the Flutter app via the
//  platform channel handler in AppDelegate.swift.
//
//  Data is stored in App Group UserDefaults under the key "tazkira_widget_data"
//  as a JSON string. This file is the single point of access to that data
//  within the widget extension — no other file should read UserDefaults directly.
//

import Foundation

// MARK: - PrayerSnapshot

/// Represents the prayer data written by the Flutter app.
/// All times are ISO-8601 UTC strings — use PrayerFormatters to convert
/// them to display strings.
struct PrayerSnapshot: Decodable {
    let fajr: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
    let nextPrayerName: String
    let nextPrayerTime: String
    let hijriDate: String
    let snapshotTimestamp: String
    
    // New fields (optional for backward compatibility with older snapshots).
    // "var = nil" keeps them optional in the memberwise initializer so
    // existing PrayerSnapshot(...) call sites keep compiling.
    var date: String? = nil
    var tomorrowDate: String? = nil
    var tomorrowFajr: String? = nil
    var tomorrowDhuhr: String? = nil
    var tomorrowAsr: String? = nil
    var tomorrowMaghrib: String? = nil
    var tomorrowIsha: String? = nil
    var tomorrowHijriDate: String? = nil
}

// MARK: - SnapshotReader

enum SnapshotReader {

    /// App Group identifier — must match Runner.entitlements and
    /// TazkiraWidget.entitlements exactly.
    private static let appGroupID = "group.com.moaz.tazkira"

    /// Key written by the Flutter platform channel handler in AppDelegate.swift.
    private static let storageKey = "tazkira_widget_data"

    /// Shared decoder instance — created once, reused on every read.
    private static let decoder = JSONDecoder()

    // MARK: Public API

    /// Reads and parses the latest prayer snapshot from the shared App Group
    /// UserDefaults container.
    ///
    /// Returns nil when:
    /// - The App Group UserDefaults container cannot be opened (e.g. App Group
    ///   not yet provisioned — returns nil gracefully so the widget shows the
    ///   placeholder state instead of crashing).
    /// - The key is absent (app has never been opened since install).
    /// - The JSON string is malformed or any required field is missing.
    static func read() -> PrayerSnapshot? {
        guard
            let defaults  = UserDefaults(suiteName: appGroupID),
            let jsonString = defaults.string(forKey: storageKey),
            let data       = jsonString.data(using: .utf8)
        else {
            return nil
        }

        return try? decoder.decode(PrayerSnapshot.self, from: data)
    }
}
