import Foundation

enum KnowledgePackDownloadCoordinatorError: LocalizedError, Equatable {
    case invalidManifest
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidManifest:
            "The downloaded knowledge pack manifest was invalid."
        case .invalidResponse:
            "The knowledge-pack download response was invalid."
        }
    }
}

final class KnowledgePackDownloadCoordinator: @unchecked Sendable {
    private let catalogClient: KnowledgePackCatalogClient
    private let session: URLSession
    private weak var connectivityService: (any ConnectivityService)?
    private let contentRepository: any KnowledgePackContentRepository
    private let installStateRepository: any KnowledgePackInstallStateRepository
    private let rebuildSearchIndex: () throws -> Void
    private let fileManager: FileManager

    init(
        catalogClient: KnowledgePackCatalogClient,
        session: URLSession = .shared,
        connectivityService: (any ConnectivityService)?,
        contentRepository: any KnowledgePackContentRepository,
        installStateRepository: any KnowledgePackInstallStateRepository,
        rebuildSearchIndex: @escaping () throws -> Void,
        fileManager: FileManager = .default
    ) {
        self.catalogClient = catalogClient
        self.session = session
        self.connectivityService = connectivityService
        self.contentRepository = contentRepository
        self.installStateRepository = installStateRepository
        self.rebuildSearchIndex = rebuildSearchIndex
        self.fileManager = fileManager
    }

    func install(_ entry: KnowledgePackCatalogEntry) async throws -> KnowledgePackInstallState {
        let previousState = try installStateRepository.state(packIdentifier: entry.id)
        let installingState = KnowledgePackInstallState(
            packIdentifier: entry.id,
            title: entry.title,
            version: entry.version,
            status: .installing,
            installedAt: previousState?.installedAt,
            contentHash: entry.contentHash,
            lastError: nil,
            recordSet: previousState?.recordSet ?? .empty,
            lastRefreshedAt: Date()
        )
        try installStateRepository.saveState(installingState)

        let temporaryDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("knowledge-pack-\(entry.id)-\(UUID().uuidString)", isDirectory: true)

        do {
            try await validateConnectivity(for: entry.manifestURL)
            try fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)

            let manifestData = try await downloadData(from: entry.manifestURL)
            try manifestData.write(
                to: temporaryDirectory.appendingPathComponent("SeedManifest.json"),
                options: .atomic
            )

            let manifest = try decodeManifest(from: manifestData)
            let baseURL = entry.manifestURL.deletingLastPathComponent()

            for pack in manifest.packs {
                let fileURL = baseURL.appendingPathComponent(pack.fileName)
                let packData = try await downloadData(from: fileURL)
                try packData.write(
                    to: temporaryDirectory.appendingPathComponent(pack.fileName),
                    options: .atomic
                )
            }

            let loader = SeedContentLoader(directoryURL: temporaryDirectory)
            let bundle = try loader.loadBundle()
            let result = try contentRepository.installKnowledgePack(
                bundle,
                previousRecordSet: previousState?.recordSet,
                importedAt: Date()
            )
            try rebuildSearchIndex()

            let installedState = KnowledgePackInstallState(
                packIdentifier: entry.id,
                title: entry.title,
                version: entry.version,
                status: .installed,
                installedAt: Date(),
                contentHash: entry.contentHash,
                lastError: nil,
                recordSet: result.recordSet,
                lastRefreshedAt: Date()
            )
            try installStateRepository.saveState(installedState)
            try? fileManager.removeItem(at: temporaryDirectory)
            return installedState
        } catch {
            try? fileManager.removeItem(at: temporaryDirectory)

            let failedState = KnowledgePackInstallState(
                packIdentifier: entry.id,
                title: entry.title,
                version: previousState?.version ?? entry.version,
                status: .failed,
                installedAt: previousState?.installedAt,
                contentHash: previousState?.contentHash ?? entry.contentHash,
                lastError: error.localizedDescription,
                recordSet: previousState?.recordSet ?? .empty,
                lastRefreshedAt: Date()
            )
            try installStateRepository.saveState(failedState)
            throw error
        }
    }

    private func validateConnectivity(for url: URL) async throws {
        guard !url.isFileURL else {
            return
        }

        let state = await MainActor.run { connectivityService?.currentState ?? .onlineUsable }
        guard state == .onlineUsable else {
            throw KnowledgePackCatalogClientError.offline
        }
    }

    private func downloadData(from url: URL) async throws -> Data {
        if url.isFileURL {
            return try Data(contentsOf: url)
        }

        try catalogClient.validateApprovedHost(for: url)
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw KnowledgePackDownloadCoordinatorError.invalidResponse
        }
        return data
    }

    private func decodeManifest(from data: Data) throws -> RemoteSeedManifest {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let manifest = try? decoder.decode(RemoteSeedManifest.self, from: data) else {
            throw KnowledgePackDownloadCoordinatorError.invalidManifest
        }
        return manifest
    }
}

private struct RemoteSeedManifest: Decodable {
    let schemaVersion: Int
    let contentPackVersion: String
    let generatedAt: Date?
    let packs: [RemoteSeedPackDescriptor]
}

private struct RemoteSeedPackDescriptor: Decodable {
    let identifier: String
    let kind: String
    let version: String
    let fileName: String
    let recordCount: Int
    let contentHash: String?
}
