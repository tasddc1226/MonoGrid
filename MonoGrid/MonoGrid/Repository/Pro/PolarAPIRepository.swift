//
//  PolarAPIRepository.swift
//  MonoGrid
//
//  Pro Business Model - Polar REST API Implementation
//  Created on 2026-01-25.
//

import Foundation

/// Polar REST API 구현체
final class PolarAPIRepository: PolarRepository {
    private let baseURL: URL
    private let session: URLSession
    private let apiKey: String

    init(
        baseURL: URL = URL(string: ProConstants.polarBaseURL)!,
        apiKey: String = ProConstants.polarAPIKey,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.session = session
    }

    // MARK: - Checkout

    func createCheckoutSession(
        productId: String,
        successUrl: String,
        cancelUrl: String
    ) async throws -> CheckoutSession {
        var request = makeRequest(endpoint: "/checkout/sessions", method: "POST")

        let body: [String: Any] = [
            "product_id": productId,
            "success_url": successUrl,
            "cancel_url": cancelUrl,
            "mode": productId.contains("monthly") ? "subscription" : "payment"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        return try JSONDecoder.polar.decode(CheckoutSession.self, from: data)
    }

    // MARK: - License

    func fetchLicense(email: String) async throws -> PolarLicenseResponse? {
        guard let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw PolarError.invalidInput
        }

        let request = makeRequest(
            endpoint: "/customers/\(encodedEmail)/subscriptions",
            method: "GET"
        )

        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
            return nil
        }

        try validateResponse(response)

        let licenses = try JSONDecoder.polar.decode([PolarLicenseResponse].self, from: data)
        // 유효한 라이선스 중 가장 최근 것 반환
        return licenses.first { $0.status == "active" }
    }

    // MARK: - Subscription

    func fetchSubscriptionStatus(subscriptionId: String) async throws -> PolarSubscriptionResponse {
        let request = makeRequest(
            endpoint: "/subscriptions/\(subscriptionId)",
            method: "GET"
        )

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        return try JSONDecoder.polar.decode(PolarSubscriptionResponse.self, from: data)
    }

    func cancelSubscription(subscriptionId: String) async throws -> Bool {
        var request = makeRequest(
            endpoint: "/subscriptions/\(subscriptionId)/cancel",
            method: "POST"
        )

        let body: [String: Any] = [
            "cancel_at_period_end": true
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PolarError.invalidResponse
        }

        return (200...299).contains(httpResponse.statusCode)
    }

    // MARK: - Helpers

    private func makeRequest(endpoint: String, method: String) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint))
        request.httpMethod = method
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PolarError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw PolarError.unauthorized
        case 404:
            throw PolarError.notFound
        case 429:
            throw PolarError.rateLimited
        default:
            throw PolarError.serverError(httpResponse.statusCode)
        }
    }
}

// MARK: - Polar Error

/// Polar API 에러
enum PolarError: LocalizedError {
    case invalidResponse
    case invalidInput
    case unauthorized
    case notFound
    case rateLimited
    case serverError(Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "유효하지 않은 응답입니다"
        case .invalidInput:
            return "유효하지 않은 입력입니다"
        case .unauthorized:
            return "인증에 실패했습니다"
        case .notFound:
            return "구매 내역을 찾을 수 없습니다"
        case .rateLimited:
            return "요청이 너무 많습니다. 잠시 후 다시 시도해주세요"
        case .serverError(let code):
            return "서버 오류가 발생했습니다 (\(code))"
        case .networkError:
            return "네트워크 오류가 발생했습니다"
        }
    }
}

// MARK: - JSON Decoder Extension

extension JSONDecoder {
    /// Polar API용 JSON Decoder
    static var polar: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
