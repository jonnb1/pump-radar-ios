// APIModels.swift
// PumpRadar
//
// Generic API envelope and paginated-response types used across all endpoints.

import Foundation

// MARK: - API Error

/// Errors that can be thrown by APIService.
enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingFailed(Error)
    case httpError(statusCode: Int, message: String)
    case unauthorized
    case networkUnavailable
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .noData:
            return "The server returned an empty response."
        case .decodingFailed(let error):
            return "Failed to decode the server response: \(error.localizedDescription)"
        case .httpError(let code, let message):
            return "Server error \(code): \(message)"
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .networkUnavailable:
            return "No internet connection. Please check your network settings."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Generic API Response

/// Standard JSON envelope returned by the backend for all endpoints.
struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: String?
    let message: String?
}

// MARK: - Paginated Response

/// Wrapper for paginated list endpoints.
struct PaginatedResponse<T: Codable>: Codable {
    let items: [T]
    let total: Int
    let page: Int
    let pageSize: Int
    let hasNextPage: Bool

    enum CodingKeys: String, CodingKey {
        case items, total, page
        case pageSize = "page_size"
        case hasNextPage = "has_next_page"
    }
}

// MARK: - Watchlist Response

/// Response model returned when adding or removing from the watchlist.
struct WatchlistResponse: Decodable {
    let watchlist: [String]
}
