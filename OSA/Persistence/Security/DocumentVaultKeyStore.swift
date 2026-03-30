import CryptoKit
import Foundation
import Security

enum DocumentVaultKeyStoreError: LocalizedError, Equatable {
    case unexpectedStatus(OSStatus)
    case invalidStoredKey

    var errorDescription: String? {
        switch self {
        case .unexpectedStatus(let status):
            "Document vault secure storage failed (\(status))."
        case .invalidStoredKey:
            "The stored document-vault key is invalid."
        }
    }
}

struct DocumentVaultKeyStore: Sendable {
    private let service: String
    private let account: String

    init(
        service: String = "com.etherealogic.OSA.document-vault",
        account: String = "document-vault-key"
    ) {
        self.service = service
        self.account = account
    }

    func loadOrCreateKey() throws -> SymmetricKey {
        if let existingKey = try loadKey() {
            return existingKey
        }

        let newKey = SymmetricKey(size: .bits256)
        try saveKey(newKey)
        return newKey
    }

    private func saveKey(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        try deleteKeyIfPresent()

        let attributes: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData: keyData
        ]

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw DocumentVaultKeyStoreError.unexpectedStatus(status)
        }
    }

    private func loadKey() throws -> SymmetricKey? {
        var query = baseQuery
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let data = item as? Data, !data.isEmpty else {
                throw DocumentVaultKeyStoreError.invalidStoredKey
            }
            return SymmetricKey(data: data)
        case errSecItemNotFound:
            return nil
        default:
            throw DocumentVaultKeyStoreError.unexpectedStatus(status)
        }
    }

    private func deleteKeyIfPresent() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw DocumentVaultKeyStoreError.unexpectedStatus(status)
        }
    }

    private var baseQuery: [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
    }
}
