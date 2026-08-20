//
//  SmallWidgetView.swift
//  TazkiraWidget
//
//  systemSmall widget — inspired by the reference design.
//
//  Visual hierarchy (top → bottom):
//  ┌─────────────────────────────┐
//  │  الصلاة القادمة             │  ← tiny caption, secondary
//  │  المغرب  06:55 م            │  ← bold name + bold time, no separator
//  │                             │
//  │  الفجر  الظهر  العصر  ...   │  ← 5 prayer mini-columns
//  │  04:13  12:58  16:32  ...   │  ← active prayer bold, others regular
//  └─────────────────────────────┘
//
//  Design rules:
//  - .widgetBackground only — no custom colour or gradient.
//  - Wallpaper shows through naturally (vibrancy).
//  - No decorative icons, no divider lines, no underlines or borders.
//  - Active prayer highlighted via typography only (bold weight).
//  - RTL layout, Arabic locale.
//  - Deep-link tap: tazkira://home.
//

import SwiftUI
import WidgetKit

// MARK: - Prayer column model

struct PrayerColumn {
    let name: String
    let isoTime: String
    let isNext: Bool
}

// MARK: - SmallWidgetView

struct SmallWidgetView: View {

    let entry: PrayerEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                contentView(snapshot: snapshot)
            } else {
                placeholderView
            }
        }
        .containerBackground(.widgetBackground, for: .widget)
        .widgetURL(URL(string: "tazkira://home"))
        .environment(\.layoutDirection, .rightToLeft)
        .environment(\.locale, Locale(identifier: "ar"))
    }

    // MARK: - Content

    private func contentView(snapshot: PrayerSnapshot) -> some View {
        let stale = PrayerFormatters.isStale(snapshot.snapshotTimestamp)
        let (nextName, nextIsoTime) = PrayerFormatters.determineNextPrayer(snapshot: snapshot, date: entry.date)

        return VStack(alignment: .center, spacing: 6) {

            // ── Next prayer header ─────────────────────────────────────
            VStack(spacing: 2) {
                Text("الصلاة القادمة")
                    .font(cairoFont(size: 10, weight: .regular))
                    .foregroundStyle(.secondary)

                // "المغرب  06:55 م" — name and time with natural spacing,
                // no dot separator, no divider line.
                HStack(spacing: 6) {
                    Text(PrayerFormatters.formatTime(nextIsoTime))
                        .font(cairoFont(size: 13, weight: .bold))
                        .foregroundStyle(stale ? .tertiary : .secondary)

                    Text(nextName)
                        .font(cairoFont(size: 15, weight: .bold))
                        .foregroundStyle(stale ? .secondary : .primary)
                }
            }

            // ── Five prayer mini-columns ───────────────────────────────
            // Active prayer: bold name + bold time.
            // Other prayers: regular name + regular time.
            // No underline, no border, no box — typography only.
            HStack(alignment: .top, spacing: 0) {
                ForEach(prayerColumns(snapshot: snapshot, date: entry.date, activeName: nextName).reversed(), id: \.name) { col in
                    prayerCell(col: col, stale: stale)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
    }

    // MARK: - Prayer cell

    private func prayerCell(col: PrayerColumn, stale: Bool) -> some View {
        let isActive = col.isNext && !stale
        return VStack(spacing: 2) {
            Text(col.name)
                .font(cairoFont(size: 9, weight: isActive ? .bold : .regular))
                .foregroundStyle(isActive ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(PrayerFormatters.formatTime(col.isoTime))
                .font(.system(size: 9,
                              weight: isActive ? .bold : .regular,
                              design: .monospaced))
                .foregroundStyle(isActive ? .primary : .tertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Placeholder

    private var placeholderView: some View {
        VStack(spacing: 6) {
            Text("تَذْكِرَة")
                .font(cairoFont(size: 14, weight: .bold))
                .foregroundStyle(.primary)

            Text("افتح التطبيق مرة واحدة\nلإعداد الويدجت")
                .font(cairoFont(size: 10, weight: .regular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(8)
    }

    // MARK: - Helpers

    private func prayerColumns(snapshot: PrayerSnapshot, date: Date, activeName: String) -> [PrayerColumn] {
        let active = PrayerFormatters.getActiveData(snapshot: snapshot, for: date)
        let prayers: [(String, String)] = [
            ("الفجر",  active.fajr),
            ("الظهر",  active.dhuhr),
            ("العصر",  active.asr),
            ("المغرب", active.maghrib),
            ("العشاء", active.isha),
        ]
        return prayers.map { name, iso in
            PrayerColumn(name: name, isoTime: iso, isNext: name == activeName)
        }
    }

    private func cairoFont(size: CGFloat, weight: Font.Weight) -> Font {
        let name: String
        switch weight {
        case .bold:     name = "Cairo-Bold"
        case .semibold: name = "Cairo-SemiBold"
        default:        name = "Cairo-Regular"
        }
        if UIFont(name: name, size: size) != nil {
            return Font.custom(name, size: size)
        }
        return Font.system(size: size, weight: weight, design: .default)
    }
}

// MARK: - Preview

#Preview("Small — content", as: .systemSmall) {
    SmallPrayerWidget()
} timeline: {
    PrayerEntry(date: .now, snapshot: nil)
    PrayerEntry(
        date: .now,
        snapshot: PrayerSnapshot(
            fajr:              "2025-07-14T01:43:00.000Z",
            dhuhr:             "2025-07-14T10:04:00.000Z",
            asr:               "2025-07-14T13:38:00.000Z",
            maghrib:           "2025-07-14T16:55:00.000Z",
            isha:              "2025-07-14T18:29:00.000Z",
            nextPrayerName:    "المغرب",
            nextPrayerTime:    "2025-07-14T16:55:00.000Z",
            hijriDate:         "18 محرم 1447 هـ",
            snapshotTimestamp: "2025-07-14T15:30:00.000Z"
        )
    )
}
