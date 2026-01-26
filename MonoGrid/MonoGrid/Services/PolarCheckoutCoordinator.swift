//
//  PolarCheckoutCoordinator.swift
//  MonoGrid
//
//  Pro Business Model - Polar Checkout WebView Coordinator
//  Created on 2026-01-25.
//

import AuthenticationServices
import SwiftUI

/// Polar 체크아웃을 위한 웹 인증 세션 관리
final class PolarCheckoutCoordinator: NSObject {
    @MainActor private var webAuthSession: ASWebAuthenticationSession?
    private let scheme = ProConstants.urlScheme

    /// 체크아웃 시작
    @MainActor
    func startCheckout(checkoutURL: URL) async throws -> CheckoutResult {
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: checkoutURL,
                callbackURLScheme: scheme
            ) { [weak self] callbackURL, error in
                if let error = error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(returning: .cancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }

                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: CheckoutError.missingCallback)
                    return
                }

                // Parse callback URL for success/failure
                if callbackURL.absoluteString.contains("success") {
                    let customerId = self?.extractCustomerId(from: callbackURL)
                    continuation.resume(returning: .success(customerId: customerId))
                } else {
                    continuation.resume(returning: .cancelled)
                }
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false

            self.webAuthSession = session

            if !session.start() {
                continuation.resume(throwing: CheckoutError.sessionStartFailed)
            }
        }
    }

    /// 체크아웃 취소
    @MainActor
    func cancelCheckout() {
        webAuthSession?.cancel()
        webAuthSession = nil
    }

    // MARK: - Private

    private func extractCustomerId(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == "customer_id" }?
            .value
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension PolarCheckoutCoordinator: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Find the key window from connected scenes
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        let window = windowScene?.windows.first(where: { $0.isKeyWindow })

        // Fallback to any available window
        if let window = window {
            return window
        }

        // Last resort: find any window from any scene
        for scene in scenes {
            if let windowScene = scene as? UIWindowScene,
               let window = windowScene.windows.first {
                return window
            }
        }

        // This should not happen in a properly configured app, but return a new window as absolute fallback
        return UIWindow()
    }
}

// MARK: - Checkout Result

/// 체크아웃 결과
enum CheckoutResult {
    case success(customerId: String?)
    case cancelled
}

// MARK: - Checkout Error

enum CheckoutError: LocalizedError {
    case missingCallback
    case invalidCallback
    case sessionStartFailed

    var errorDescription: String? {
        switch self {
        case .missingCallback:
            return "결제 응답을 받지 못했습니다"
        case .invalidCallback:
            return "결제 응답이 유효하지 않습니다"
        case .sessionStartFailed:
            return "결제 화면을 열 수 없습니다"
        }
    }
}
