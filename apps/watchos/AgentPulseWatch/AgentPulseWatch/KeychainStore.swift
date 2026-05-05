import Foundation
import Security

final class KeychainStore {
    private let service = "com.paulfecto.AgentPulse.watchkitapp"

    func loadSession() -> AgentPulseSession? {
        guard let data = read(account: "session") else { return nil }
        return try? JSONDecoder().decode(AgentPulseSession.self, from: data)
    }

    func saveSession(_ session: AgentPulseSession) throws {
        let data = try JSONEncoder().encode(session)
        try write(data: data, account: "session")
    }

    func clearSession() {
        delete(account: "session")
    }

    func fingerprint() -> String {
        if let data = read(account: "fingerprint"), let value = String(data: data, encoding: .utf8) {
            return value
        }
        let value = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        try? write(data: Data(value.utf8), account: "fingerprint")
        return value
    }

    private func read(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        return item as? Data
    }

    private func write(data: Data, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecSuccess { return }
        if status != errSecItemNotFound { throw KeychainError(status: status) }

        var create = query
        create[kSecValueData as String] = data
        create[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let createStatus = SecItemAdd(create as CFDictionary, nil)
        if createStatus != errSecSuccess { throw KeychainError(status: createStatus) }
    }

    private func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

struct KeychainError: Error {
    let status: OSStatus
}
