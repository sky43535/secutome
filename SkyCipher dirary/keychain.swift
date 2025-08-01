//
//  keychain.swift
//  SkyCipher dirary
//
//  Created by Owner on 7/29/25.
//
import Foundation
import Security
import CryptoKit
import LocalAuthentication

final class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    private let keyTag = "com.scdiary.encryptionkey"

    /// Create or retrieve symmetric key protected by biometrics
    func getOrCreateKey() throws -> SymmetricKey {
        if let key = try? getKey() {
            return key
        }
        return try createKey()
    }

    /// Retrieve key from Keychain (biometric prompt happens here)
    func getKey() throws -> SymmetricKey {
        let context = LAContext()
        context.localizedReason = "Authenticate to access your encryption key"
        context.interactionNotAllowed = false  // Allow user interaction

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }

        guard let keyData = item as? Data else {
            throw NSError(domain: "KeychainHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid key data"])
        }
        return SymmetricKey(data: keyData)
    }

    /// Create new random symmetric key and store it with biometric protection
    func createKey() throws -> SymmetricKey {
        var keyData = Data(count: 32)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        guard result == errSecSuccess else {
            throw NSError(domain: "KeychainHelper", code: Int(result), userInfo: nil)
        }

        let accessControl = SecAccessControlCreateWithFlags(nil,
                                                          kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                                          .biometryCurrentSet,
                                                          nil)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessControl as String: accessControl,
            kSecUseAuthenticationContext as String: LAContext() // fresh context
        ]

        // Remove old key if exists
        SecItemDelete([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keyTag
        ] as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }

        return SymmetricKey(data: keyData)
    }
}
