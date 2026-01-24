//
//  HabitEntity.swift
//  MonoGrid
//
//  Created on 2026-01-23.
//

import AppIntents
import SwiftUI

/// App Entity representing a habit for use in Intents and Shortcuts
struct HabitEntity: AppEntity {
    // MARK: - Properties

    /// Unique identifier (UUID as string)
    var id: String

    /// Habit title/name
    var title: String

    /// SF Symbol name for the icon
    var iconSymbol: String

    /// Color hex string
    var colorHex: String

    // MARK: - Type Display

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("습관"),
            numericFormat: LocalizedStringResource("\(placeholder: .int) 습관")
        )
    }

    // MARK: - Display Representation

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: nil,
            image: .init(systemName: iconSymbol)
        )
    }

    // MARK: - Default Query

    static var defaultQuery = HabitEntityQuery()
}

// MARK: - Identifiable

extension HabitEntity: Identifiable {}

// MARK: - Equatable & Hashable

extension HabitEntity: Equatable, Hashable {
    static func == (lhs: HabitEntity, rhs: HabitEntity) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
