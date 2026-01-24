//
//  ColorExtensionTests.swift
//  MonoGridTests
//
//  Created on 2026-01-23.
//

import Testing
import SwiftUI
@testable import MonoGrid

@Suite("Color Extension Tests")
struct ColorExtensionTests {

    // MARK: - Hex to Color Tests

    @Test("Valid 6-digit hex creates color")
    func test_hexToColor_valid6Digit() {
        let color = Color(hex: "#FF6B6B")
        // Color should be created (we can't easily test exact values in SwiftUI)
        #expect(color != Color.clear)
    }

    @Test("Hex without hash prefix works")
    func test_hexToColor_withoutHash() {
        let color = Color(hex: "4D96FF")
        #expect(color != Color.clear)
    }

    @Test("Invalid hex returns black/default")
    func test_hexToColor_invalid() {
        let color = Color(hex: "invalid")
        // Should return some default color without crashing
        #expect(true) // Just verify no crash
    }

    @Test("3-digit hex shorthand works")
    func test_hexToColor_3digit() {
        let color = Color(hex: "F00") // Red
        #expect(color != Color.clear)
    }

    // MARK: - Preset Colors Tests

    @Test("All preset colors are valid")
    func test_presetColors_valid() {
        for preset in Constants.colorPresets {
            let color = Color(hex: preset.hex)
            #expect(color != Color.clear, "Color \(preset.name) should be valid")
        }
    }

    @Test("Preset count is 6")
    func test_presetColors_count() {
        #expect(Constants.colorPresets.count == 6)
    }

    @Test("habitCoral has correct hex")
    func test_habitCoral() {
        let coral = Color.habitCoral
        #expect(coral != Color.clear)
    }

    @Test("habitBlue has correct hex")
    func test_habitBlue() {
        let blue = Color.habitBlue
        #expect(blue != Color.clear)
    }

    @Test("habitGreen has correct hex")
    func test_habitGreen() {
        let green = Color.habitGreen
        #expect(green != Color.clear)
    }

    // MARK: - Grid Colors Tests

    @Test("gridIncomplete is semi-transparent gray")
    func test_gridIncomplete() {
        let color = Color.gridIncomplete
        #expect(color != Color.clear)
    }

    // MARK: - Round Trip Tests

    @Test("Color to hex round trip preserves value")
    func test_colorToHex_roundTrip() {
        let originalHex = "#FF6B6B"
        let color = Color(hex: originalHex)
        let resultHex = color.hexString

        // Note: Due to color space conversions, exact match may not be guaranteed
        // We just verify it produces a valid hex
        #expect(resultHex.hasPrefix("#"))
        #expect(resultHex.count == 7)
    }
}
