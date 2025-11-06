//
//  AppleAuthResult.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

struct AppleAuthResult {
    let appleSub: String
    let fullName: PersonNameComponents?
    let email: String?
    let identityToken: Data?
    let authorizationCode: Data?

    // MARK: - Computed Properties

    var displayName: String {
        if let fullName = fullName {
            let formatter = PersonNameComponentsFormatter()
            formatter.style = .default
            return formatter.string(from: fullName)
        }
        return email ?? "User"
    }

    // MARK: - Convenience

    var hasValidToken: Bool {
        identityToken != nil
    }

    // MARK: - Preview Data

    static var preview: AppleAuthResult {
        var nameComponents = PersonNameComponents()
        nameComponents.givenName = "John"
        nameComponents.familyName = "Doe"

        return AppleAuthResult(
            appleSub: "preview-apple-sub-123",
            fullName: nameComponents,
            email: "john.doe@privaterelay.appleid.com",
            identityToken: Data(),
            authorizationCode: Data()
        )
    }

    static var previewWithoutEmail: AppleAuthResult {
        var nameComponents = PersonNameComponents()
        nameComponents.givenName = "Jane"
        nameComponents.familyName = "Smith"

        return AppleAuthResult(
            appleSub: "preview-apple-sub-456",
            fullName: nameComponents,
            email: nil,
            identityToken: Data(),
            authorizationCode: Data()
        )
    }
}
