//
//  AppError.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

enum AppError: LocalizedError, Equatable {
    case networkFailure
    case networkTimeout
    case invalidResponse
    case insufficientCredits
    case unauthorized
    case invalidDevice
    case userNotFound
    case networkError(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .networkFailure:
            return "error.network.failure"
        case .networkTimeout:
            return "error.network.timeout"
        case .invalidResponse:
            return "error.network.invalid_response"
        case .insufficientCredits:
            return "error.credit.insufficient"
        case .unauthorized:
            return "error.auth.unauthorized"
        case .invalidDevice:
            return "error.auth.device_invalid"
        case .userNotFound:
            return "error.user.not_found"
        case .networkError(let message):
            return message
        case .unknown(let message):
            return message
        }
    }

    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.networkFailure, .networkFailure),
             (.networkTimeout, .networkTimeout),
             (.invalidResponse, .invalidResponse),
             (.insufficientCredits, .insufficientCredits),
             (.unauthorized, .unauthorized),
             (.invalidDevice, .invalidDevice),
             (.userNotFound, .userNotFound):
            return true
        case (.networkError(let lhsMsg), .networkError(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.unknown(let lhsMsg), .unknown(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}
