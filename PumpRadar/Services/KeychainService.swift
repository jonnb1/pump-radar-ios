// KeychainService.swift
// PumpRadar
//
// Thin wrapper around Security framework for storing and retrieving
// sensitive values (tokens) from the iOS Keychain.

import Foundation
import Security

// MARK: - KeychainService

final class KeychainService {

    // MARK: - Shared Instance

    static let shared = KeychainService()

    private init() {}

    // MARK: - Public Interface

    /// Saves a string value under the given key. Overwrites any existing entry.
    /// - Parameters:
    ///   - value: The plaintext string to store.
    ///   - key: A unique identifier for the keychain item.
    /// - Returns: `true` on success.
    @discardableResult
    func save(value: String, key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        delete(key: key) // Ensure no duplicate
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    /// Reads the string value stored under the given key.
    /// - Parameter key: The key used when saving.
    /// - Returns: The stored string, or `nil` if not found.
    func read(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else { return nil }
        return string
    }

    /// Deletes the keychain item for the given key.
    /// - Parameter key: The key of the item to remove.
    /// - Returns: `true` if the item was successfully deleted or did not exist.
    @discardableResult
    func delete(key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
