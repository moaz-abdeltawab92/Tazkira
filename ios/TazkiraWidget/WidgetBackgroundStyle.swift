//
//  WidgetBackgroundStyle.swift
//  TazkiraWidget
//
//  Shared ShapeStyle used by all widget families so the system default
//  background (wallpaper vibrancy) shows through, matching Apple's
//  widget templates.
//

import SwiftUI

extension ShapeStyle where Self == AnyShapeStyle {
    static var widgetBackground: AnyShapeStyle { AnyShapeStyle(.fill.tertiary) }
}
