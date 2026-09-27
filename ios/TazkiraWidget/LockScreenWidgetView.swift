//
//  LockScreenWidgetView.swift
//  TazkiraWidget
//
//  accessoryRectangular Lock Screen widget (iOS 16+).
//
//  This is the closest faithful adaptation of the reference image within
//  WidgetKit's accessoryRectangular constraints (~338×57pt, ~3 text lines).
//
//  Visual hierarchy:
//  ┌────────────────────────────────────────────────────────┐
//  │  الصلاة القادمة: المغرب  06:55 م   (bold, prominent)  │  line 1
//  │  الفجر    الظهر    العصر    المغرب    العشاء           │  line 2
//  │  04:13   12:58   16:32   19:59   21:31                │  line 3
//  └────────────────────────────────────────────────────────┘
//
//  Design rules:
//  - .widgetBackground — system vibrancy, wallpaper shows through.
//  - No custom colours, no cards, no borders, no icons.
//  - Active prayer: bold throughout.
//  - Other prayers: regular weight.
//  - Arabic only, RTL layout.
//  - Deep-link tap: tazkira://home.
//

import SwiftUI
import WidgetKit

// MARK: - LockScreenWidgetView

@available(iOS 16.0, *)
struct LockScreenWidgetView: View {

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
        let (nextName, nextIsoTime) = PrayerFormatters.determineNextPrayer(snapshot: snapshot, date: entry.date)
        
        return VStack(alignment: .leading, spacing: 3) {

            // ── Line 1: next prayer — the visual focus ─────────────────
            // "الصلاة القادمة: المغرب  06:55 م"
            // Bold throughout to match the reference's "Fajr is at 04:13" prominence.
            HStack(spacing: 4) {
                Text(PrayerFormatters.formatTime(nextIsoTime))
                    .font(cairoFont(size: 12, weight: .semibold))

                Text(nextName)
                    .font(cairoFont(size: 14, weight: .bold))

                Text("الصلاة القادمة:")
                    .font(cairoFont(size: 11, weight: .regular))
                    .opacity(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // ── Lines 2–3: five prayer columns ────────────────────────
            // Prayer names on line 2, times on line 3.
            // Active prayer: bold. Others: regular.
            HStack(alignment: .top, spacing: 0) {
                ForEach(prayerColumns(snapshot: snapshot, date: entry.date, activeName: nextName).reversed(), id: \.name) { col in
                    prayerCell(col: col)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Prayer cell

    private func prayerCell(col: PrayerColumn) -> some View {
        VStack(spacing: 1) {
            Text(col.name)
                .font(cairoFont(size: 10, weight: col.isNext ? .bold : .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(PrayerFormatters.formatTime(col.isoTime))
                .font(cairoFont(size: 10, weight: col.isNext ? .bold : .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .opacity(col.isNext ? 1.0 : 0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Placeholder

    // accessoryRectangular has very limited height — keep placeholder to one line.
    private var placeholderView: some View {
        Text("افتح التطبيق مرة واحدة لإعداد الويدجت")
            .font(cairoFont(size: 11, weight: .regular))
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .opacity(0.7)
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

    /// Cairo font with system Arabic fallback — same strategy as all other widget views.
    /// UIFont availability check prevents blank labels when the TTF is not yet bundled.
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

@available(iOS 16.0, *)
#Preview("Lock Screen", as: .accessoryRectangular) {
    LockScreenPrayerWidget()
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
            nextPrayerName:    "الفجر",
            nextPrayerTime:    "2025-07-14T01:43:00.000Z",
            hijriDate:         "18 محرم 1447 هـ",
            snapshotTimestamp: "2025-07-14T15:30:00.000Z"
        )
    )
}
