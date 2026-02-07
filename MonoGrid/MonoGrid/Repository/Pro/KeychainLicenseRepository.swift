//
//  KeychainLicenseRepository.swift
//  MonoGrid
//
//  Pro Business Model - Keychain-based License Repository
//  Created on 2026-01-25.
//

import Foundation

/// Keychain 기반 라이선스 저장소
final class KeychainLicenseRepository: LicenseRepository {
    private let keychain = KeychainHelper.shared

    func save(_ license: ProLicense) throws {
        try keychain.save(license: license)
    }

    func load() -> ProLicense? {
        keychain.loadLicense()
    }

    func delete() {
        keychain.deleteLicense()
    }

    func exists() -> Bool {
        keychain.licenseExists()
    }
}
