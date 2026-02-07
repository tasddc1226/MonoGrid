//
//  ProFeature.swift
//  MonoGrid
//
//  Pro Business Model - Pro Feature Definitions
//  Created on 2026-01-25.
//

import Foundation

/// Pro 전용 기능 정의
enum ProFeature: String, CaseIterable, Identifiable {
    case signatureColors = "signature_colors"
    case gridCustomization = "grid_customization"
    case proAppIcons = "pro_app_icons"
    case weekdayAnalysis = "weekday_analysis"
    case streakStatistics = "streak_statistics"
    case hdExport = "hd_export"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .signatureColors:
            return "12가지 시그니처 컬러"
        case .gridCustomization:
            return "그리드 스타일 커스터마이징"
        case .proAppIcons:
            return "Pro 전용 앱 아이콘"
        case .weekdayAnalysis:
            return "요일별 달성 분석"
        case .streakStatistics:
            return "스트릭 통계"
        case .hdExport:
            return "인스타그램용 고해상도 내보내기"
        }
    }

    var description: String {
        switch self {
        case .signatureColors:
            return "더 다양한 컬러로 습관을 표현하세요"
        case .gridCustomization:
            return "그리드 모서리와 테두리를 커스터마이징하세요"
        case .proAppIcons:
            return "독특한 앱 아이콘으로 홈 화면을 꾸미세요"
        case .weekdayAnalysis:
            return "요일별 습관 달성률을 확인하세요"
        case .streakStatistics:
            return "최장 연속 기록과 통계를 확인하세요"
        case .hdExport:
            return "1080x1080 고해상도로 내보내기"
        }
    }

    /// 페이월 트리거 시 사용할 식별자
    var analyticsId: String {
        rawValue
    }

    /// 아이콘 이름
    var iconName: String {
        switch self {
        case .signatureColors:
            return "paintpalette.fill"
        case .gridCustomization:
            return "square.grid.3x3"
        case .proAppIcons:
            return "app.fill"
        case .weekdayAnalysis:
            return "chart.bar.fill"
        case .streakStatistics:
            return "flame.fill"
        case .hdExport:
            return "arrow.up.doc.fill"
        }
    }
}
