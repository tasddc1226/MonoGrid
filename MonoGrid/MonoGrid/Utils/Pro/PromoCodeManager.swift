//
//  PromoCodeManager.swift
//  MonoGrid
//
//  Pro Business Model - Promo Code Validation Manager
//  Created on 2026-01-26.
//

import Foundation
import CryptoKit

/// Promo code validation result
enum PromoCodeResult {
    case success
    case invalid
    case alreadyUsed
    case alreadyPro
}

/// Manages promo code validation and redemption
@MainActor
final class PromoCodeManager {
    static let shared = PromoCodeManager()

    // MARK: - Constants

    private let usedCodesKey = "MonoGrid.UsedPromoCodes"

    // MARK: - Properties

    private var validCodes: Set<String> {
        guard let codesString = Bundle.main.infoDictionary?["PromoCodes"] as? String,
              !codesString.isEmpty,
              codesString != "$(PROMO_CODES)" else {
            #if DEBUG
            print("PromoCodeManager: No promo codes configured in Info.plist")
            #endif
            return []
        }

        let codes = codesString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
            .filter { !$0.isEmpty }

        return Set(codes)
    }

    private var usedCodes: Set<String> {
        get {
            let codes = UserDefaults.standard.stringArray(forKey: usedCodesKey) ?? []
            return Set(codes)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: usedCodesKey)
        }
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Validate and redeem a promo code
    /// - Parameters:
    ///   - code: The promo code to validate
    ///   - licenseManager: The license manager to grant Pro access
    /// - Returns: The result of the promo code validation
    func redeemCode(_ code: String, licenseManager: LicenseManager) -> PromoCodeResult {
        let normalizedCode = code.trimmingCharacters(in: .whitespaces).uppercased()

        // Check if already Pro
        if licenseManager.hasProAccess {
            return .alreadyPro
        }

        // Check if code already used on this device
        if usedCodes.contains(normalizedCode) {
            return .alreadyUsed
        }

        // Validate code
        guard validCodes.contains(normalizedCode) else {
            return .invalid
        }

        // Grant Pro Lifetime access using the promo code factory method
        let promoId = "promo_\(normalizedCode.prefix(4))_\(UUID().uuidString.prefix(8))"
        let license = ProLicense.fromPromoCode(promoId: promoId)

        licenseManager.saveLicense(license)

        // Mark code as used
        var codes = usedCodes
        codes.insert(normalizedCode)
        usedCodes = codes

        return .success
    }

    /// Check if a code is valid (without redeeming)
    func isValidCode(_ code: String) -> Bool {
        let normalizedCode = code.trimmingCharacters(in: .whitespaces).uppercased()
        return validCodes.contains(normalizedCode)
    }

    /// Check if a code has already been used
    func isCodeUsed(_ code: String) -> Bool {
        let normalizedCode = code.trimmingCharacters(in: .whitespaces).uppercased()
        return usedCodes.contains(normalizedCode)
    }

    // MARK: - Reset Methods

    /// Clear all used promo codes (for data reset)
    func clearUsedCodes() {
        UserDefaults.standard.removeObject(forKey: usedCodesKey)
    }

    // MARK: - Utility Methods

    /// Generate SHA256 hash for a code (for secure code storage)
    static func hashCode(_ code: String) -> String {
        let normalizedCode = code.trimmingCharacters(in: .whitespaces).uppercased()
        let data = Data(normalizedCode.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    #if DEBUG
    /// Reset used codes (for testing only)
    func resetUsedCodes() {
        UserDefaults.standard.removeObject(forKey: usedCodesKey)
    }

    /// Debug: Print configured promo codes
    func debugPrintCodes() {
        print("Valid promo codes: \(validCodes)")
        print("Used promo codes: \(usedCodes)")
    }
    #endif
}
