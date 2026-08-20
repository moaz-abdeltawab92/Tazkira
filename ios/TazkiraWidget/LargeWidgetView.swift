//
//  LargeWidgetView.swift
//  TazkiraWidget
//
//  systemLarge widget — extends the medium design with the Hijri date.
//
//  Visual hierarchy (top → bottom):
//  ┌──────────────────────────────────────────────────────────────┐
//  │  18 محرم 1447 هـ                                            │  ← Hijri date, top
//  │                                                              │
//  │  الصلاة القادمة                                              │  ← small caption
//  │  المغرب  06:55 م                                             │  ← bold name + time
//  │                                                              │
//  │  الفجر    الظهر    العصر    المغرب    العشاء                 │  ← 5 columns
//  │  04:13   12:58   16:32   19:59   21:31                      │
//  └──────────────────────────────────────────────────────────────┘
//
//  Design rules:
//  - .widgetBackground only — no custom colour or gradient.
//  - No icons, no dividers, no borders, no underlines.
//  - Active prayer: bold name + bold time.
//  - Other prayers: regular name + regular time.
//  - RTL layout, Arabic locale.
//  - Deep-link tap: tazkira://home.
//

import SwiftUI
import WidgetKit

// MARK: - LargeWidgetView

struct LargeWidgetView: View {

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
        let activeData = PrayerFormatters.getActiveData(snapshot: snapshot, for: entry.date)

        return VStack(alignment: .leading, spacing: 16) {

            // ── Hijri date ─────────────────────────────────────────────
            // Only shown when available; empty string falls back gracefully.
            if !activeData.hijriDate.isEmpty {
                Text(activeData.hijriDate)
                    .font(cairoFont(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // ── Next prayer header — two-line hierarchy ────────────────
            VStack(alignment: .leading, spacing: 2) {
                Text("الصلاة القادمة")
                    .font(cairoFont(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    Text(PrayerFormatters.formatTime(nextIsoTime))
                        .font(cairoFont(size: 16, weight: .semibold))
                        .foregroundStyle(stale ? .tertiary : .secondary)

                    Text(nextName)
                        .font(cairoFont(size: 22, weight: .bold))
                        .foregroundStyle(stale ? .secondary : .primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // ── Five prayer columns ────────────────────────────────────
            HStack(alignment: .top, spacing: 0) {
                ForEach(prayerColumns(snapshot: snapshot, date: entry.date, activeName: nextName).reversed(), id: \.name) { col in
                    prayerCell(col: col, stale: stale)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    // MARK: - Prayer cell

    private func prayerCell(col: PrayerColumn, stale: Bool) -> some View {
        let isActive = col.isNext && !stale
        return VStack(spacing: 3) {
            Text(col.name)
                .font(cairoFont(size: 12, weight: isActive ? .bold : .regular))
                .foregroundStyle(isActive ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(PrayerFormatters.formatTime(col.isoTime))
                .font(.system(size: 12,
                              weight: isActive ? .bold : .regular,
                              design: .monospaced))
                .foregroundStyle(isActive ? .primary : .tertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Placeholder

    private var placeholderView: some View {
        VStack(spacing: 8) {
            Text("تَذْكِرَة")
                .font(cairoFont(size: 16, weight: .bold))
                .foregroundStyle(.primary)

            Text("افتح التطبيق مرة واحدة لإعداد الويدجت")
                .font(cairoFont(size: 12, weight: .regular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
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

#Preview("Large — content", as: .systemLarge) {
    LargePrayerWidget()
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
