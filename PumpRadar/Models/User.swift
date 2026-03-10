// User.swift
// PumpRadar
//
// Data models for authentication and user account management.

import Foundation

// MARK: - User

/// An authenticated application user.
struct User: Codable, Equatable {
    let id: String
    let email: String
    let username: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, email, username
        case createdAt = "created_at"
    }
}

// MARK: - Auth Request / Response

/// Payload sent to the login endpoint.
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

/// Payload sent to the sign-up endpoint.
struct SignUpRequest: Encodable {
    let email: String
    let username: String
    let password: String
}

/// Response returned on successful authentication.
struct AuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let user: User

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

// MARK: - Preview Data

#if DEBUG
extension User {
    static let preview = User(
        id: "usr_001",
        email: "demo@pumprader.io",
        username: "demo_user",
        createdAt: Date()
    )
}
#endif
