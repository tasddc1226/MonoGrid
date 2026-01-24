//
//  MonoGridWidgetBundle.swift
//  MonoGridWidget
//
//  Created on 2026-01-23.
//

import WidgetKit
import SwiftUI

/// Main entry point for all MonoGrid widgets
@main
struct MonoGridWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Home Screen Widgets
        SmallHabitWidget()
        MediumHabitWidget()
        LargeHabitWidget()

        // Lock Screen Widgets
        CircularLockWidget()
        InlineLockWidget()
    }
}
