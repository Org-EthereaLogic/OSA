import Foundation

enum KnowledgePackCatalogClientError: LocalizedError, Equatable {
    case offline
    case unapprovedHost(String)
    case invalidResponse
    case missingCatalog

    var errorDescription: String? {
        switch self {
        case .offline:
            "Knowledge packs are unavailable while offline."
        case .unapprovedHost(let host):
            "Knowledge pack host \(host) is not approved."
        case .invalidResponse:
            "The knowledge-pack catalog response was invalid."
        case .missingCatalog:
            "The bundled knowledge-pack catalog is unavailable in this build."
        }
    }
}

final class KnowledgePackCatalogClient: @unchecked Sendable {
    static let approvedHosts: Set<String> = ["downloads.etherealogic.com"]

    private let catalogURL: URL?
    private let session: URLSession
    private weak var connectivityService: (any ConnectivityService)?

    init(
        catalogURL: URL? = nil,
        bundle: Bundle = .main,
        session: URLSession = .shared,
        connectivityService: (any ConnectivityService)?
    ) {
        self.catalogURL = catalogURL ?? bundle.url(
            forResource: "catalog",
            withExtension: "json",
            subdirectory: "KnowledgePacks"
        )
        self.session = session
        self.connectivityService = connectivityService
    }

    func fetchCatalog() async throws -> KnowledgePackCatalog {
        let catalogURL = try resolvedCatalogURL()

        let data: Data

        if catalogURL.isFileURL {
            data = try loadLocalCatalogData(from: catalogURL)
        } else {
            try await validateConnectivity()
            try validateApprovedHost(for: catalogURL)

            let (remoteData, response) = try await session.data(from: catalogURL)
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {
                throw KnowledgePackCatalogClientError.invalidResponse
            }
            data = remoteData
        }

        return try decodeCatalog(from: data, relativeTo: catalogURL)
    }

    func loadLocalCatalog() throws -> KnowledgePackCatalog {
        let catalogURL = try resolvedCatalogURL()
        guard catalogURL.isFileURL else {
            throw KnowledgePackCatalogClientError.invalidResponse
        }

        let data = try loadLocalCatalogData(from: catalogURL)
        return try decodeCatalog(from: data, relativeTo: catalogURL)
    }

    func validateApprovedHost(for url: URL) throws {
        guard !url.isFileURL else {
            return
        }

        guard let host = url.host, Self.approvedHosts.contains(host) else {
            throw KnowledgePackCatalogClientError.unapprovedHost(url.host ?? "unknown")
        }
    }

    private func resolvedCatalogURL() throws -> URL {
        guard let catalogURL else {
            throw KnowledgePackCatalogClientError.missingCatalog
        }
        return catalogURL
    }

    private func loadLocalCatalogData(from url: URL) throws -> Data {
        do {
            return try Data(contentsOf: url)
        } catch {
            throw KnowledgePackCatalogClientError.missingCatalog
        }
    }

    private func decodeCatalog(
        from data: Data,
        relativeTo catalogURL: URL
    ) throws -> KnowledgePackCatalog {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(CatalogPayload.self, from: data)
        let packs = try payload.packs.map {
            KnowledgePackCatalogEntry(
                id: $0.id,
                title: $0.title,
                summary: $0.summary,
                version: $0.version,
                manifestURL: try resolveManifestURL(for: $0, relativeTo: catalogURL),
                contentHash: $0.contentHash
            )
        }

        return KnowledgePackCatalog(
            generatedAt: payload.generatedAt,
            packs: packs
        )
    }

    private func resolveManifestURL(
        for payload: CatalogPackPayload,
        relativeTo catalogURL: URL
    ) throws -> URL {
        if let manifestURL = payload.manifestURL {
            if manifestURL.scheme == nil {
                return catalogURL.deletingLastPathComponent()
                    .appendingPathComponent(manifestURL.relativePath)
            }

            return manifestURL
        }

        if let manifestPath = payload.manifestPath?.trimmingCharacters(in: .whitespacesAndNewlines),
           !manifestPath.isEmpty {
            return catalogURL.deletingLastPathComponent().appendingPathComponent(manifestPath)
        }

        throw KnowledgePackCatalogClientError.invalidResponse
    }

    private func validateConnectivity() async throws {
        let state = await MainActor.run { connectivityService?.currentState ?? .onlineUsable }
        guard state == .onlineUsable else {
            throw KnowledgePackCatalogClientError.offline
        }
    }
}

private struct CatalogPayload: Decodable {
    let generatedAt: Date?
    let packs: [CatalogPackPayload]
}

private struct CatalogPackPayload: Decodable {
    let id: String
    let title: String
    let summary: String
    let version: String
    let manifestURL: URL?
    let manifestPath: String?
    let contentHash: String
}
