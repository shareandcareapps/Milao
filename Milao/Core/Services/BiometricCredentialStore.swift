import Foundation
import Security
import LocalAuthentication

// MARK: - Biometric Credential Store
// Stores the sign-in email/password in the Keychain behind a biometric-protected
// access control (Secure Enclave-backed). Reading the item itself triggers the
// Face ID / Touch ID prompt at the OS level — there's no separate LAContext call.

enum BiometricCredentialStore {
    private static let service = "com.milao.biometricLogin"
    private static let account = "milao.credentials"

    struct StoredCredentials: Codable {
        let email: String
        let password: String
    }

    enum StoreError: Error {
        case accessControlUnavailable
        case keychain(OSStatus)
        case decode
    }

    static func save(email: String, password: String) throws {
        clear()
        let payload = try JSONEncoder().encode(StoredCredentials(email: email, password: password))
        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet,
            nil
        ) else { throw StoreError.accessControlUnavailable }

        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrService as String:       service,
            kSecAttrAccount as String:       account,
            kSecValueData as String:         payload,
            kSecAttrAccessControl as String: access,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw StoreError.keychain(status) }
    }

    /// Prompts Face ID / Touch ID (via the Keychain's own access control) and
    /// returns the stored credentials on success.
    static func load(reason: String) throws -> StoredCredentials {
        let context = LAContext()
        context.localizedReason = reason

        let query: [String: Any] = [
            kSecClass as String:                    kSecClassGenericPassword,
            kSecAttrService as String:               service,
            kSecAttrAccount as String:                account,
            kSecReturnData as String:                 true,
            kSecUseAuthenticationContext as String:   context,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            throw StoreError.keychain(status)
        }
        guard let creds = try? JSONDecoder().decode(StoredCredentials.self, from: data) else {
            throw StoreError.decode
        }
        return creds
    }

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String:      kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
