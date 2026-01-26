//
//  LicenseRepository.swift
//  MonoGrid
//
//  Pro Business Model - License Repository Protocol
//  Created on 2026-01-25.
//

import Foundation

/// 라이선스 저장소 프로토콜
protocol LicenseRepository {
    func save(_ license: ProLicense) throws
    func load() -> ProLicense?
    func delete()
    func exists() -> Bool
}
