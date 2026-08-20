//
//  TazkiraWidgetBundle.swift
//  TazkiraWidget
//
//  Entry point for all Tazkira widget configurations.
//  Replaces the Xcode-generated stub which referenced the demo emoji widgets.
//
//  Families provided:
//  - systemSmall    (iOS 14+) → SmallPrayerWidget
//  - systemMedium   (iOS 14+) → MediumPrayerWidget
//  - systemLarge    (iOS 14+) → LargePrayerWidget
//  - accessoryRectangular (iOS 16+) → LockScreenPrayerWidget
//

import WidgetKit
import SwiftUI

@main
struct TazkiraWidgetBundle: WidgetBundle {
    var body: some Widget {
        SmallPrayerWidget()
        MediumPrayerWidget()
        LargePrayerWidget()

        // Lock Screen widget requires iOS 16. The @available guard ensures the
        // bundle compiles cleanly on the iOS 14 deployment target and the widget
        // is offered only on devices that support it.
        if #available(iOS 16.0, *) {
            LockScreenPrayerWidget()
        }
    }
}
