//
//  KeychainHelper.swift
//  MonoGrid
//
//  Pro Business Model - Keychain CRUD Helper
//  Created on 2026-01-25.
//

import Foundation
import Security

/// Keychain CRUD 헬퍼
final class KeychainHelper {
    static let shared = KeychainHelper()

    private let service = ProConstants.keychainService

    private init() {}

    // MARK: - License Operations

    /// 라이선스 저장
    func save(license: ProLicense) throws {
        let data = try JSONEncoder().encode(license)

        // 기존 항목 삭제 후 새로 추가
        deleteLicense()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: ProConstants.keychainLicenseAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    /// 라이선스 로드
    func loadLicense() -> ProLicense? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: ProConstants.keychainLicenseAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }

        return try? JSONDecoder().decode(ProLicense.self, from: data)
    }

    /// 라이선스 삭제
    func deleteLicense() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: ProConstants.keychainLicenseAccount
        ]

        SecItemDelete(query as CFDictionary)
    }

    /// 라이선스 존재 여부
    func licenseExists() -> Bool {
        loadLicense() != nil
    }

    // MARK: - Generic Operations

    /// Generic data 저장
    func save(_ data: Data, forKey key: String) throws {
        delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    /// Generic data 로드
    func load(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            return nil
        }

        return result as? Data
    }

    /// Generic data 삭제
    func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Keychain Error

enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "라이선스 저장 실패 (코드: \(status))"
        case .loadFailed(let status):
            return "라이선스 로드 실패 (코드: \(status))"
        case .encodingFailed:
            return "데이터 인코딩 실패"
        case .decodingFailed:
            return "데이터 디코딩 실패"
        }
    }
}
