//
//  PrayerEntry.swift
//  TazkiraWidget
//
//  The TimelineEntry used by all four Tazkira widget families.
//  Wraps an optional PrayerSnapshot so widget views can show a placeholder
//  state when no data is available, rather than crashing or showing stale data.
//

import WidgetKit

/// A single timeline entry carrying a prayer snapshot for one point in time.
///
/// `date` tells WidgetKit when this entry should be rendered.
/// `snapshot` is nil when no data is available — widget views must handle
/// this case by showing the placeholder UI.
struct PrayerEntry: TimelineEntry {
    /// The date at which this entry should be displayed.
    let date: Date

    /// The prayer data snapshot, or nil when unavailable.
    let snapshot: PrayerSnapshot?
}
