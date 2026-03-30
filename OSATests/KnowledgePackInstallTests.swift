import CryptoKit
import Foundation
import SwiftData
import XCTest
@testable import OSA

@MainActor
final class KnowledgePackInstallTests: XCTestCase {
    func testCatalogClientLoadsLocalCatalogAndResolvesRelativeManifestPaths() async throws {
        let fileManager = FileManager.default
        let temporaryDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("knowledge-pack-catalog-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryDirectory) }

        try fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        let packDirectory = temporaryDirectory.appendingPathComponent("water-checks", isDirectory: true)
        try fileManager.createDirectory(at: packDirectory, withIntermediateDirectories: true)

        let catalogData = Data(
            """
            {
              "generatedAt": "2026-03-29T00:00:00Z",
              "packs": [
                {
                  "id": "water-checks",
                  "title": "Water Checks",
                  "summary": "Bundled pack",
                  "version": "1.0.0",
                  "manifestPath": "water-checks/SeedManifest.json",
                  "contentHash": "catalog-hash"
                }
              ]
            }
            """.utf8
        )
        try catalogData.write(to: temporaryDirectory.appendingPathComponent("catalog.json"), options: .atomic)

        let client = KnowledgePackCatalogClient(
            catalogURL: temporaryDirectory.appendingPathComponent("catalog.json"),
            session: URLSession(configuration: .ephemeral),
            connectivityService: StubKnowledgePackConnectivityService()
        )

        let catalog = try await client.fetchCatalog()

        XCTAssertEqual(catalog.packs.count, 1)
        XCTAssertEqual(catalog.packs[0].id, "water-checks")
        XCTAssertTrue(catalog.packs[0].manifestURL.isFileURL)
        XCTAssertEqual(catalog.packs[0].manifestURL.lastPathComponent, "SeedManifest.json")
        XCTAssertTrue(catalog.packs[0].isBundled)
        XCTAssertFalse(catalog.packs[0].requiresConnectivity)
    }

    func testBundledBootstrapperInstallsBundledPacksOnStartup() throws {
        let fileManager = FileManager.default
        let temporaryDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("knowledge-pack-bootstrap-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryDirectory) }

        let templateID = UUID()
        let itemID = UUID()
        let packData = checklistPackData(templateID: templateID, itemID: itemID)
        let manifestData = manifestData(
            fileName: "water-checks.json",
            recordCount: 1,
            contentHash: sha256Hex(packData)
        )
        let catalogURL = try writeBundledKnowledgePackFixture(
            to: temporaryDirectory,
            packDirectoryName: "water-checks",
            packFileName: "water-checks.json",
            manifestData: manifestData,
            packData: packData,
            entryID: "water-checks",
            title: "Water Checks",
            summary: "Bundled water rotation drills",
            version: "1.0.0",
            contentHash: sha256Hex(manifestData)
        )

        let installStateRepository = InMemoryKnowledgePackInstallStateRepository()
        let contentRepository = RecordingKnowledgePackContentRepository()
        let installDate = Date(timeIntervalSince1970: 1_743_206_400)
        let bootstrapper = BundledKnowledgePackBootstrapper(
            catalogClient: KnowledgePackCatalogClient(
                catalogURL: catalogURL,
                session: URLSession(configuration: .ephemeral),
                connectivityService: StubKnowledgePackConnectivityService()
            ),
            contentRepository: contentRepository,
            installStateRepository: installStateRepository,
            now: { installDate }
        )

        _ = bootstrapper.installBundledPacksIfNeeded()

        XCTAssertEqual(contentRepository.installedBundles.count, 1)
        let installedState = try XCTUnwrap(installStateRepository.state(packIdentifier: "water-checks"))
        XCTAssertEqual(installedState.status, .installed)
        XCTAssertEqual(installedState.installedAt, installDate)
        XCTAssertEqual(installedState.recordSet.checklistTemplateIDs, [templateID])
        XCTAssertEqual(installedState.contentHash, sha256Hex(manifestData))
    }

    func testBundledBootstrapperSkipsCurrentInstalledPack() throws {
        let fileManager = FileManager.default
        let temporaryDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("knowledge-pack-skip-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryDirectory) }

        let templateID = UUID()
        let itemID = UUID()
        let packData = checklistPackData(templateID: templateID, itemID: itemID)
        let manifestData = manifestData(
            fileName: "water-checks.json",
            recordCount: 1,
            contentHash: sha256Hex(packData)
        )
        let catalogURL = try writeBundledKnowledgePackFixture(
            to: temporaryDirectory,
            packDirectoryName: "water-checks",
            packFileName: "water-checks.json",
            manifestData: manifestData,
            packData: packData,
            entryID: "water-checks",
            title: "Water Checks",
            summary: "Bundled water rotation drills",
            version: "1.0.0",
            contentHash: sha256Hex(manifestData)
        )

        let installDate = Date(timeIntervalSince1970: 1_743_206_400)
        let existingState = KnowledgePackInstallState(
            packIdentifier: "water-checks",
            title: "Water Checks",
            version: "1.0.0",
            status: .installed,
            installedAt: installDate,
            contentHash: sha256Hex(manifestData),
            lastError: nil,
            recordSet: KnowledgePackRecordSet(
                chapterIDs: [],
                quickCardIDs: [],
                checklistTemplateIDs: [templateID],
                fieldReferenceIDs: []
            ),
            lastRefreshedAt: installDate
        )
        let installStateRepository = InMemoryKnowledgePackInstallStateRepository()
        try installStateRepository.saveState(existingState)

        let contentRepository = RecordingKnowledgePackContentRepository()
        let bootstrapper = BundledKnowledgePackBootstrapper(
            catalogClient: KnowledgePackCatalogClient(
                catalogURL: catalogURL,
                session: URLSession(configuration: .ephemeral),
                connectivityService: StubKnowledgePackConnectivityService()
            ),
            contentRepository: contentRepository,
            installStateRepository: installStateRepository,
            now: { Date(timeIntervalSince1970: 1_743_292_800) }
        )

        _ = bootstrapper.installBundledPacksIfNeeded()

        XCTAssertTrue(contentRepository.installedBundles.isEmpty)
        XCTAssertEqual(try installStateRepository.state(packIdentifier: "water-checks"), existingState)
    }

    func testInstallKnowledgePackUpsertsIncomingRecordsAndRemovesPreviousPackOwnedRecordsOnly() throws {
        let container = try makeContentContainer()
        let context = container.mainContext
        let repository = SwiftDataContentRepository(modelContext: context)

        let unrelatedQuickCard = QuickCard(
            id: UUID(),
            title: "Home Quick Card",
            slug: "home-quick-card",
            category: "home",
            summary: "Existing bundled content",
            bodyMarkdown: "leave untouched",
            priority: 10,
            relatedSectionIDs: [],
            tags: [],
            lastReviewedAt: nil,
            largeTypeLayoutVersion: 1
        )
        context.insert(PersistedQuickCard(from: unrelatedQuickCard))
        try context.save()

        let bundleOne = makeBundle(label: "one")
        let firstResult = try repository.installKnowledgePack(bundleOne, previousRecordSet: nil, importedAt: Date())

        XCTAssertNotNil(try repository.chapter(id: bundleOne.chapters[0].id))
        XCTAssertNotNil(try repository.quickCard(id: bundleOne.quickCards[0].id))
        XCTAssertNotNil(try repository.entry(id: bundleOne.fieldReferences[0].id))
        XCTAssertNotNil(try repository.quickCard(id: unrelatedQuickCard.id))

        let bundleTwo = makeBundle(label: "two", includeChecklist: false, includeFieldReference: false)
        let secondResult = try repository.installKnowledgePack(
            bundleTwo,
            previousRecordSet: firstResult.recordSet,
            importedAt: Date()
        )

        XCTAssertNil(try repository.chapter(id: bundleOne.chapters[0].id))
        XCTAssertNil(try repository.quickCard(id: bundleOne.quickCards[0].id))
        XCTAssertNil(try repository.entry(id: bundleOne.fieldReferences[0].id))
        XCTAssertNotNil(try repository.chapter(id: bundleTwo.chapters[0].id))
        XCTAssertNotNil(try repository.quickCard(id: bundleTwo.quickCards[0].id))
        XCTAssertNotNil(try repository.quickCard(id: unrelatedQuickCard.id))

        let templates = try context.fetch(FetchDescriptor<PersistedChecklistTemplate>())
        XCTAssertTrue(templates.isEmpty)
        XCTAssertEqual(secondResult.recordSet.chapterIDs, [bundleTwo.chapters[0].id])
        XCTAssertEqual(secondResult.recordSet.quickCardIDs, [bundleTwo.quickCards[0].id])
        XCTAssertTrue(secondResult.recordSet.checklistTemplateIDs.isEmpty)
        XCTAssertTrue(secondResult.recordSet.fieldReferenceIDs.isEmpty)
    }

    func testCoordinatorInstallsValidatedPackAndRebuildsSearchIndex() async throws {
        let packURL = URL(string: "https://downloads.etherealogic.com/osa/knowledge-packs/water-checks/SeedManifest.json")!
        let templateID = UUID()
        let itemID = UUID()
        let packData = checklistPackData(templateID: templateID, itemID: itemID)
        let manifestData = manifestData(
            fileName: "water-checks.json",
            recordCount: 1,
            contentHash: sha256Hex(packData)
        )
        defer { StubKnowledgePackURLProtocol.responseProvider = nil }

        StubKnowledgePackURLProtocol.responseProvider = { request in
            let responseURL = request.url ?? packURL
            let body: Data

            switch responseURL.lastPathComponent {
            case "SeedManifest.json":
                body = manifestData
            case "water-checks.json":
                body = packData
            default:
                body = Data()
            }

            return (
                body,
                HTTPURLResponse(
                    url: responseURL,
                    statusCode: 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": "application/json"]
                )!
            )
        }

        let session = makeStubSession()
        let connectivity = StubKnowledgePackConnectivityService()
        let installStateRepository = InMemoryKnowledgePackInstallStateRepository()
        let contentRepository = RecordingKnowledgePackContentRepository()
        var rebuildCalled = false

        let coordinator = KnowledgePackDownloadCoordinator(
            catalogClient: KnowledgePackCatalogClient(
                catalogURL: URL(string: "https://downloads.etherealogic.com/osa/knowledge-packs/catalog.json")!,
                session: session,
                connectivityService: connectivity
            ),
            session: session,
            connectivityService: connectivity,
            contentRepository: contentRepository,
            installStateRepository: installStateRepository,
            rebuildSearchIndex: { rebuildCalled = true }
        )

        let entry = KnowledgePackCatalogEntry(
            id: "water-checks",
            title: "Water Checks",
            summary: "Curated water rotation drills",
            version: "1.0.0",
            manifestURL: packURL,
            contentHash: "catalog-hash"
        )

        let installedState = try await coordinator.install(entry)

        XCTAssertEqual(installedState.status, .installed)
        XCTAssertEqual(installedState.recordSet.checklistTemplateIDs, [templateID])
        XCTAssertEqual(contentRepository.installedBundles.count, 1)
        XCTAssertTrue(rebuildCalled)
        XCTAssertEqual(
            try installStateRepository.state(packIdentifier: entry.id)?.status,
            .installed
        )
    }

    func testCoordinatorInstallsBundledFilePackWhileOffline() async throws {
        let fileManager = FileManager.default
        let temporaryDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("knowledge-pack-bundled-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryDirectory) }

        try fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        let packDirectory = temporaryDirectory.appendingPathComponent("water-checks", isDirectory: true)
        try fileManager.createDirectory(at: packDirectory, withIntermediateDirectories: true)

        let templateID = UUID()
        let itemID = UUID()
        let packData = checklistPackData(templateID: templateID, itemID: itemID)
        let manifestData = manifestData(
            fileName: "water-checks.json",
            recordCount: 1,
            contentHash: sha256Hex(packData)
        )

        try manifestData.write(to: packDirectory.appendingPathComponent("SeedManifest.json"), options: .atomic)
        try packData.write(to: packDirectory.appendingPathComponent("water-checks.json"), options: .atomic)

        let connectivity = StubKnowledgePackConnectivityService()
        connectivity.currentState = .offline
        let installStateRepository = InMemoryKnowledgePackInstallStateRepository()
        let contentRepository = RecordingKnowledgePackContentRepository()
        var rebuildCalled = false

        let catalogClient = KnowledgePackCatalogClient(
            catalogURL: temporaryDirectory.appendingPathComponent("catalog.json"),
            session: URLSession(configuration: .ephemeral),
            connectivityService: connectivity
        )
        let coordinator = KnowledgePackDownloadCoordinator(
            catalogClient: catalogClient,
            session: URLSession(configuration: .ephemeral),
            connectivityService: connectivity,
            contentRepository: contentRepository,
            installStateRepository: installStateRepository,
            rebuildSearchIndex: { rebuildCalled = true }
        )

        let entry = KnowledgePackCatalogEntry(
            id: "water-checks",
            title: "Water Checks",
            summary: "Bundled water rotation drills",
            version: "1.0.0",
            manifestURL: packDirectory.appendingPathComponent("SeedManifest.json"),
            contentHash: sha256Hex(manifestData)
        )

        let installedState = try await coordinator.install(entry)

        XCTAssertEqual(installedState.status, .installed)
        XCTAssertEqual(installedState.recordSet.checklistTemplateIDs, [templateID])
        XCTAssertEqual(contentRepository.installedBundles.count, 1)
        XCTAssertTrue(rebuildCalled)
    }

    func testCoordinatorMarksInstallFailedAndPreservesPreviousMetadataWhenManifestIsInvalid() async throws {
        let packURL = URL(string: "https://downloads.etherealogic.com/osa/knowledge-packs/water-checks/SeedManifest.json")!
        defer { StubKnowledgePackURLProtocol.responseProvider = nil }

        StubKnowledgePackURLProtocol.responseProvider = { request in
            (
                Data("not-json".utf8),
                HTTPURLResponse(
                    url: request.url ?? packURL,
                    statusCode: 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": "application/json"]
                )!
            )
        }

        let session = makeStubSession()
        let connectivity = StubKnowledgePackConnectivityService()
        let installStateRepository = InMemoryKnowledgePackInstallStateRepository()
        let previousInstalledAt = Date(timeIntervalSince1970: 1_743_206_400)
        let previousState = KnowledgePackInstallState(
            packIdentifier: "water-checks",
            title: "Water Checks",
            version: "0.9.0",
            status: .installed,
            installedAt: previousInstalledAt,
            contentHash: "previous-hash",
            lastError: nil,
            recordSet: KnowledgePackRecordSet(
                chapterIDs: [UUID()],
                quickCardIDs: [UUID()],
                checklistTemplateIDs: [],
                fieldReferenceIDs: []
            ),
            lastRefreshedAt: previousInstalledAt
        )
        try installStateRepository.saveState(previousState)

        let coordinator = KnowledgePackDownloadCoordinator(
            catalogClient: KnowledgePackCatalogClient(
                catalogURL: URL(string: "https://downloads.etherealogic.com/osa/knowledge-packs/catalog.json")!,
                session: session,
                connectivityService: connectivity
            ),
            session: session,
            connectivityService: connectivity,
            contentRepository: RecordingKnowledgePackContentRepository(),
            installStateRepository: installStateRepository,
            rebuildSearchIndex: {}
        )

        let entry = KnowledgePackCatalogEntry(
            id: "water-checks",
            title: "Water Checks",
            summary: "Curated water rotation drills",
            version: "1.0.0",
            manifestURL: packURL,
            contentHash: "new-hash"
        )

        do {
            _ = try await coordinator.install(entry)
            XCTFail("Expected invalid manifest failure")
        } catch {
            XCTAssertEqual(error as? KnowledgePackDownloadCoordinatorError, .invalidManifest)
        }

        let failedState = try XCTUnwrap(installStateRepository.state(packIdentifier: entry.id))
        XCTAssertEqual(failedState.status, .failed)
        XCTAssertEqual(failedState.version, previousState.version)
        XCTAssertEqual(failedState.installedAt, previousState.installedAt)
        XCTAssertEqual(failedState.recordSet, previousState.recordSet)
        XCTAssertEqual(failedState.contentHash, previousState.contentHash)
        XCTAssertNotNil(failedState.lastError)
    }

    private func makeContentContainer() throws -> ModelContainer {
        let schema = Schema([
            PersistedHandbookChapter.self,
            PersistedHandbookSection.self,
            PersistedQuickCard.self,
            PersistedFieldReferenceEntry.self,
            PersistedChecklistTemplate.self,
            PersistedChecklistTemplateItem.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeBundle(
        label: String,
        includeChecklist: Bool = true,
        includeFieldReference: Bool = true
    ) -> SeedContentBundle {
        let chapterID = UUID()
        let sectionID = UUID()
        let quickCardID = UUID()
        let templateID = UUID()
        let fieldReferenceID = UUID()
        let manifest = SeedContentManifest(
            schemaVersion: 1,
            contentPackVersion: "1.0.\(label)",
            generatedAt: nil,
            packs: []
        )
        let chapter = HandbookChapter(
            id: chapterID,
            slug: "chapter-\(label)",
            title: "Chapter \(label)",
            summary: "Summary \(label)",
            sortOrder: 10,
            tags: [label],
            version: 1,
            isSeeded: true,
            lastReviewedAt: nil,
            sections: [
                HandbookSection(
                    id: sectionID,
                    chapterID: chapterID,
                    parentSectionID: nil,
                    heading: "Section \(label)",
                    bodyMarkdown: "Body \(label)",
                    plainText: "Body \(label)",
                    sortOrder: 10,
                    tags: [label],
                    safetyLevel: .normal,
                    chunkGroupID: "chunk-\(label)",
                    version: 1,
                    lastReviewedAt: nil
                )
            ]
        )
        let quickCard = QuickCard(
            id: quickCardID,
            title: "Quick Card \(label)",
            slug: "quick-card-\(label)",
            category: "preparedness",
            summary: "Summary \(label)",
            bodyMarkdown: "Body \(label)",
            priority: 50,
            relatedSectionIDs: [sectionID],
            tags: [label],
            lastReviewedAt: nil,
            largeTypeLayoutVersion: 1
        )
        let checklistTemplate = ChecklistTemplate(
            id: templateID,
            title: "Checklist \(label)",
            slug: "checklist-\(label)",
            category: "preparedness",
            description: "Checklist \(label)",
            estimatedMinutes: 15,
            tags: [label],
            sourceType: .seeded,
            presentationStyle: .standard,
            timerProfile: nil,
            lastReviewedAt: nil,
            items: [
                ChecklistTemplateItem(
                    id: UUID(),
                    templateID: templateID,
                    text: "Step \(label)",
                    detail: nil,
                    sortOrder: 100,
                    isOptional: false,
                    riskLevel: nil
                )
            ]
        )
        let fieldReference = FieldReferenceEntry(
            id: fieldReferenceID,
            slug: "field-reference-\(label)",
            title: "Field Reference \(label)",
            category: .waterTreatment,
            summary: "Field summary \(label)",
            sortOrder: 10,
            sections: [
                FieldReferenceSection(
                    title: "Reference \(label)",
                    bodyMarkdown: "Reference body \(label)",
                    plainText: "Reference body \(label)",
                    sortOrder: 100
                )
            ],
            relatedSectionIDs: [sectionID],
            tags: [label],
            safetyLevel: .normal,
            lastReviewedAt: nil
        )

        return SeedContentBundle(
            manifest: manifest,
            chapters: [chapter],
            quickCards: [quickCard],
            checklistTemplates: includeChecklist ? [checklistTemplate] : [],
            fieldReferences: includeFieldReference ? [fieldReference] : []
        )
    }

    private func makeStubSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubKnowledgePackURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func manifestData(
        fileName: String,
        recordCount: Int,
        contentHash: String
    ) -> Data {
        let manifest = """
        {
          "schemaVersion": 1,
          "contentPackVersion": "1.0.0",
          "generatedAt": "2026-03-29T00:00:00Z",
          "packs": [
            {
              "identifier": "water-checks",
              "kind": "checklist-templates",
              "version": "1.0.0",
              "fileName": "\(fileName)",
              "recordCount": \(recordCount),
              "contentHash": "\(contentHash)"
            }
          ]
        }
        """
        return Data(manifest.utf8)
    }

    private func checklistPackData(templateID: UUID, itemID: UUID) -> Data {
        let pack = """
        {
          "templates": [
            {
              "id": "\(templateID.uuidString)",
              "title": "Water Cache Refresh",
              "slug": "water-cache-refresh",
              "category": "water",
              "description": "Rotate stored water locally.",
              "estimatedMinutes": 15,
              "tags": ["water"],
              "sourceType": "seeded",
              "presentationStyle": "standard",
              "timerProfile": null,
              "lastReviewedAt": null,
              "items": [
                {
                  "id": "\(itemID.uuidString)",
                  "text": "Inspect container seals",
                  "detail": null,
                  "sortOrder": 100,
                  "isOptional": false,
                  "riskLevel": null
                }
              ]
            }
          ]
        }
        """
        return Data(pack.utf8)
    }

    private func writeBundledKnowledgePackFixture(
        to directoryURL: URL,
        packDirectoryName: String,
        packFileName: String,
        manifestData: Data,
        packData: Data,
        entryID: String,
        title: String,
        summary: String,
        version: String,
        contentHash: String
    ) throws -> URL {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let packDirectory = directoryURL.appendingPathComponent(packDirectoryName, isDirectory: true)
        try fileManager.createDirectory(at: packDirectory, withIntermediateDirectories: true)
        try manifestData.write(to: packDirectory.appendingPathComponent("SeedManifest.json"), options: .atomic)
        try packData.write(to: packDirectory.appendingPathComponent(packFileName), options: .atomic)

        let catalogData = Data(
            """
            {
              "generatedAt": "2026-03-29T00:00:00Z",
              "packs": [
                {
                  "id": "\(entryID)",
                  "title": "\(title)",
                  "summary": "\(summary)",
                  "version": "\(version)",
                  "manifestPath": "\(packDirectoryName)/SeedManifest.json",
                  "contentHash": "\(contentHash)"
                }
              ]
            }
            """.utf8
        )
        let catalogURL = directoryURL.appendingPathComponent("catalog.json")
        try catalogData.write(to: catalogURL, options: .atomic)
        return catalogURL
    }

    private func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

private final class StubKnowledgePackConnectivityService: ConnectivityService, @unchecked Sendable {
    @MainActor var currentState: ConnectivityState = .onlineUsable

    @MainActor func stateStream() -> AsyncStream<ConnectivityState> {
        AsyncStream { continuation in
            continuation.yield(currentState)
            continuation.finish()
        }
    }

    func start() {}
    func stop() {}
    @MainActor func setSyncInProgress() {}
    @MainActor func clearSyncInProgress() {}
}

private final class StubKnowledgePackURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var responseProvider: ((URLRequest) -> (Data, HTTPURLResponse))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let provider = Self.responseProvider else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        let (data, response) = provider(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private final class InMemoryKnowledgePackInstallStateRepository: KnowledgePackInstallStateRepository {
    private var statesByIdentifier: [String: KnowledgePackInstallState] = [:]

    func listStates() throws -> [KnowledgePackInstallState] {
        statesByIdentifier.values.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func state(packIdentifier: String) throws -> KnowledgePackInstallState? {
        statesByIdentifier[packIdentifier]
    }

    func saveState(_ state: KnowledgePackInstallState) throws {
        statesByIdentifier[state.packIdentifier] = state
    }
}

private final class RecordingKnowledgePackContentRepository: KnowledgePackContentRepository {
    private(set) var installedBundles: [SeedContentBundle] = []

    func installKnowledgePack(
        _ bundle: SeedContentBundle,
        previousRecordSet: KnowledgePackRecordSet?,
        importedAt: Date
    ) throws -> KnowledgePackInstallResult {
        _ = previousRecordSet
        _ = importedAt
        installedBundles.append(bundle)
        return KnowledgePackInstallResult(
            recordSet: KnowledgePackRecordSet(
                chapterIDs: bundle.chapters.map(\.id),
                quickCardIDs: bundle.quickCards.map(\.id),
                checklistTemplateIDs: bundle.checklistTemplates.map(\.id),
                fieldReferenceIDs: bundle.fieldReferences.map(\.id)
            ),
            chapterCount: bundle.chapters.count,
            quickCardCount: bundle.quickCards.count,
            checklistTemplateCount: bundle.checklistTemplates.count,
            fieldReferenceCount: bundle.fieldReferences.count
        )
    }
}
