//
//  TazkiraWidget.swift
//  TazkiraWidget
//
//  Declares the four concrete Widget conformances used by TazkiraWidgetBundle.
//  Replaces the Xcode-generated emoji demo stub.
//
//  Each widget uses StaticConfiguration (no user-configurable intents) backed
//  by PrayerTimelineProvider, and routes to its dedicated SwiftUI view.
//

import WidgetKit
import SwiftUI

// MARK: - Small

struct SmallPrayerWidget: Widget {
    let kind = "com.moaz.tazkira.small"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimelineProvider()) { entry in
            SmallWidgetView(entry: entry)
        }
        .configurationDisplayName("تذكرة – الصلاة القادمة")
        .description("الصلاة القادمة ومواقيت الصلوات الخمس.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Medium

struct MediumPrayerWidget: Widget {
    let kind = "com.moaz.tazkira.medium"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimelineProvider()) { entry in
            MediumWidgetView(entry: entry)
        }
        .configurationDisplayName("تذكرة – أوقات الصلاة")
        .description("الصلاة القادمة ومواقيت الصلوات الخمس.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Large

struct LargePrayerWidget: Widget {
    let kind = "com.moaz.tazkira.large"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimelineProvider()) { entry in
            LargeWidgetView(entry: entry)
        }
        .configurationDisplayName("تذكرة – الجدول اليومي")
        .description("التاريخ الهجري والصلاة القادمة ومواقيت الصلوات الخمس.")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Lock Screen (iOS 16+)

@available(iOS 16.0, *)
struct LockScreenPrayerWidget: Widget {
    let kind = "com.moaz.tazkira.lockscreen"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimelineProvider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("تذكرة – شاشة القفل")
        .description("الصلاة القادمة ومواقيت الصلوات الخمس على شاشة القفل.")
        .supportedFamilies([.accessoryRectangular])
    }
}
