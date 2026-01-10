import Foundation
import Security

/// Service for securely storing sensitive data like API keys and auth tokens
public final class KeychainService: @unchecked Sendable {
    public static let shared = KeychainService()

    private let serviceName = "com.vulpino.widgets"

    private init() {}

    /// Save headers for a widget config
    public func saveHeaders(_ headers: [HTTPHeader], for configId: UUID) throws {
        let key = "headers-\(configId.uuidString)"
        let data = try JSONEncoder().encode(headers)
        try save(data: data, for: key)
    }

    /// Load headers for a widget config
    public func loadHeaders(for configId: UUID) -> [HTTPHeader] {
        let key = "headers-\(configId.uuidString)"
        guard let data = load(for: key) else { return [] }

        do {
            return try JSONDecoder().decode([HTTPHeader].self, from: data)
        } catch {
            return []
        }
    }

    /// Delete headers for a widget config
    public func deleteHeaders(for configId: UUID) {
        let key = "headers-\(configId.uuidString)"
        delete(for: key)
    }

    // MARK: - Low-level Keychain Operations

    private func save(data: Data, for key: String) throws {
        // Delete existing item first
        delete(for: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    private func load(for key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private func delete(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}

public enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to Keychain (status: \(status))"
        case .loadFailed(let status):
            return "Failed to load from Keychain (status: \(status))"
        }
    }
}
