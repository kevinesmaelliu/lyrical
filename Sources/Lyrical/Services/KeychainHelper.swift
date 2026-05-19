import Foundation
import Security

enum KeychainAccount: String {
    case accessToken
    case refreshToken

    var label: String {
        switch self {
        case .accessToken: "Lyrical — Spotify session"
        case .refreshToken: "Lyrical — Spotify stay signed in"
        }
    }
}

enum KeychainHelper {
    /// Internal key; macOS may show the human-readable label below instead.
    private static let service = "com.lyrical.app.spotify-session"
    private static let legacyService = "com.lyrical.spotify"
    private static let description =
        "Stores Spotify login tokens so Lyrical can read the current song and show synced lyrics. Your Spotify password is never saved."

    static func save(_ value: String, account: KeychainAccount) {
        store(value, account: account)
    }

    static func read(account: KeychainAccount) -> String? {
        if let current = readFromService(account, service: service) {
            return current
        }
        if let legacy = readFromService(account, service: legacyService) {
            store(legacy, account: account)
            deleteFromService(account, service: legacyService)
            return legacy
        }
        return nil
    }

    static func delete(account: KeychainAccount) {
        deleteFromService(account, service: service)
        deleteFromService(account, service: legacyService)
    }

    static func deleteAll() {
        delete(account: .accessToken)
        delete(account: .refreshToken)
    }

    private static func store(_ value: String, account: KeychainAccount) {
        let data = Data(value.utf8)
        let query = baseQuery(account: account, service: service)
        SecItemDelete(query as CFDictionary)

        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrLabel as String] = account.label
        add[kSecAttrDescription as String] = description
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }

    private static func readFromService(_ account: KeychainAccount, service: String) -> String? {
        var query = baseQuery(account: account, service: service)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8)
        else { return nil }
        return value
    }

    private static func deleteFromService(_ account: KeychainAccount, service: String) {
        SecItemDelete(baseQuery(account: account, service: service) as CFDictionary)
    }

    private static func baseQuery(account: KeychainAccount, service: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account.rawValue,
        ]
    }
}
