import Foundation
import Security

enum BraveSearchCredentialStoreError: LocalizedError, Equatable {
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .unexpectedStatus(let status):
            "Secure storage failed (\(status))."
        }
    }
}

/// Stores the optional Brave Search API key in the device keychain.
struct BraveSearchCredentialStore: Sendable {
    private let service: String
    private let account: String

    init(
        service: String = "com.etherealogic.OSA.discovery.brave-search",
        account: String = DiscoverySettings.braveSearchAPIKeyKey
    ) {
        self.service = service
        self.account = account
    }

    func loadStoredAPIKey() -> String? {
        (try? loadAPIKey()) ?? nil
    }

    func saveAPIKey(_ apiKey: String) throws {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            try deleteAPIKey()
            return
        }

        try deleteAPIKey()

        let attributes: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData: Data(trimmed.utf8)
        ]

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw BraveSearchCredentialStoreError.unexpectedStatus(status)
        }
    }

    func deleteAPIKey() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw BraveSearchCredentialStoreError.unexpectedStatus(status)
        }
    }

    private func loadAPIKey() throws -> String? {
        var query = baseQuery
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let data = item as? Data else { return nil }
            return String(data: data, encoding: .utf8)
        case errSecItemNotFound:
            return nil
        default:
            throw BraveSearchCredentialStoreError.unexpectedStatus(status)
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

/// A web search result from a search API.
struct WebSearchResult: Equatable, Sendable {
    let title: String
    let url: URL
    let snippet: String?
}

/// Protocol for web search clients.
protocol WebSearchClient: Sendable {
    func search(query: String) async throws -> [WebSearchResult]
}

/// Minimal Brave Search API client for the free tier (2000 queries/month).
///
/// The API key is user-provided via Settings and stored in the device keychain.
/// Budget tracking uses a simple monthly counter to avoid exceeding the free tier.
final class BraveSearchClient: WebSearchClient, @unchecked Sendable {
    private let apiKey: String
    private let session: URLSession
    private let defaults: UserDefaults

    init(
        apiKey: String,
        session: URLSession = .shared,
        defaults: UserDefaults = .standard
    ) {
        self.apiKey = apiKey
        self.session = session
        self.defaults = defaults
    }

    func search(query: String) async throws -> [WebSearchResult] {
        guard canQuery() else { return [] }

        var components = URLComponents(string: "https://api.search.brave.com/res/v1/web/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "count", value: "10")
        ]

        guard let url = components.url else { return [] }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Subscription-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return []
        }

        incrementQueryCount()

        let decoded = try JSONDecoder().decode(BraveSearchResponse.self, from: data)
        return (decoded.web?.results ?? []).compactMap { result in
            guard let url = URL(string: result.url) else { return nil }
            return WebSearchResult(
                title: result.title,
                url: url,
                snippet: result.description
            )
        }
    }

    // MARK: - Budget Tracking

    private func canQuery() -> Bool {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let storedMonth = defaults.integer(forKey: DiscoverySettings.braveSearchQueryMonthKey)

        if storedMonth != currentMonth {
            defaults.set(currentMonth, forKey: DiscoverySettings.braveSearchQueryMonthKey)
            defaults.set(0, forKey: DiscoverySettings.braveSearchQueryCountKey)
            return true
        }

        let count = defaults.integer(forKey: DiscoverySettings.braveSearchQueryCountKey)
        return count < DiscoverySettings.monthlyQueryBudget
    }

    private func incrementQueryCount() {
        let count = defaults.integer(forKey: DiscoverySettings.braveSearchQueryCountKey)
        defaults.set(count + 1, forKey: DiscoverySettings.braveSearchQueryCountKey)
    }
}

// MARK: - Brave Search Response DTO

struct BraveSearchResponse: Codable, Sendable {
    let web: WebResults?

    struct WebResults: Codable, Sendable {
        let results: [Result]
    }

    struct Result: Codable, Sendable {
        let title: String
        let url: String
        let description: String?
    }
}
