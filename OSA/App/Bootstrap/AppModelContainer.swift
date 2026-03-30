import Foundation
import SwiftData

private extension ProcessInfo {
    /// Returns `true` when the process is hosted by XCTest or a UI-test runner.
    var isRunningTests: Bool {
        environment["XCTestConfigurationFilePath"] != nil
            || environment["XCTestSessionIdentifier"] != nil
    }

    var isRunningUITests: Bool {
        arguments.contains("UI-TESTING")
    }

    var isRunningUnitTests: Bool {
        isRunningTests && !isRunningUITests
    }
}

struct BundledKnowledgePackBootstrapper {
    let catalogClient: KnowledgePackCatalogClient
    let contentRepository: any KnowledgePackContentRepository
    let installStateRepository: any KnowledgePackInstallStateRepository
    let now: () -> Date

    init(
        catalogClient: KnowledgePackCatalogClient,
        contentRepository: any KnowledgePackContentRepository,
        installStateRepository: any KnowledgePackInstallStateRepository,
        now: @escaping () -> Date = Date.init
    ) {
        self.catalogClient = catalogClient
        self.contentRepository = contentRepository
        self.installStateRepository = installStateRepository
        self.now = now
    }

    @discardableResult
    func installBundledPacksIfNeeded() -> [KnowledgePackInstallState] {
        guard let catalog = try? catalogClient.loadLocalCatalog() else {
            return []
        }

        return catalog.packs.compactMap { entry in
            guard entry.isBundled else { return nil }
            return installIfNeeded(entry)
        }
    }

    private func installIfNeeded(_ entry: KnowledgePackCatalogEntry) -> KnowledgePackInstallState? {
        let previousState = try? installStateRepository.state(packIdentifier: entry.id)
        if let previousState,
           previousState.status == .installed,
           previousState.version == entry.version,
           previousState.contentHash == entry.contentHash {
            return previousState
        }

        let installTimestamp = now()
        let installingState = KnowledgePackInstallState(
            packIdentifier: entry.id,
            title: entry.title,
            version: entry.version,
            status: .installing,
            installedAt: previousState?.installedAt,
            contentHash: entry.contentHash,
            lastError: nil,
            recordSet: previousState?.recordSet ?? .empty,
            lastRefreshedAt: installTimestamp
        )

        do {
            try installStateRepository.saveState(installingState)

            let loader = SeedContentLoader(
                directoryURL: entry.manifestURL.deletingLastPathComponent()
            )
            let bundle = try loader.loadBundle()
            let result = try contentRepository.installKnowledgePack(
                bundle,
                previousRecordSet: previousState?.recordSet,
                importedAt: installTimestamp
            )

            let installedState = KnowledgePackInstallState(
                packIdentifier: entry.id,
                title: entry.title,
                version: entry.version,
                status: .installed,
                installedAt: installTimestamp,
                contentHash: entry.contentHash,
                lastError: nil,
                recordSet: result.recordSet,
                lastRefreshedAt: installTimestamp
            )
            try installStateRepository.saveState(installedState)
            return installedState
        } catch {
            let failedState = KnowledgePackInstallState(
                packIdentifier: entry.id,
                title: entry.title,
                version: previousState?.version ?? entry.version,
                status: .failed,
                installedAt: previousState?.installedAt,
                contentHash: previousState?.contentHash ?? entry.contentHash,
                lastError: error.localizedDescription,
                recordSet: previousState?.recordSet ?? .empty,
                lastRefreshedAt: installTimestamp
            )
            try? installStateRepository.saveState(failedState)
            return failedState
        }
    }
}

/// Shared runtime for App Intents and other non-SwiftUI entry points.
///
/// Lazily creates the same `AppDependencies` graph used by the main app.
/// Thread-safe through `@MainActor` isolation.
enum SharedRuntime {
    @MainActor
    private static var _dependencies: AppDependencies?

    @MainActor
    private static var _navigationCoordinator: AppNavigationCoordinator?

    @MainActor
    private static var _onscreenContentManager: OnscreenContentManager?

    @MainActor
    static var dependencies: AppDependencies {
        if let existing = _dependencies { return existing }
        let container = AppModelContainer.makeShared()
        let deps = AppDependencies.live(modelContainer: container)
        _dependencies = deps
        return deps
    }

    @MainActor
    static var navigationCoordinator: AppNavigationCoordinator {
        if let existing = _navigationCoordinator { return existing }
        let coordinator = AppNavigationCoordinator()
        _navigationCoordinator = coordinator
        return coordinator
    }

    /// Called by `OSAApp.init()` to share the already-created dependencies.
    @MainActor
    static func install(_ deps: AppDependencies) {
        _dependencies = deps
    }

    /// Called by `OSAApp` to share the navigation coordinator with App Intents.
    @MainActor
    static func installNavigationCoordinator(_ coordinator: AppNavigationCoordinator) {
        _navigationCoordinator = coordinator
    }

    @MainActor
    static var onscreenContentManager: OnscreenContentManager {
        if let existing = _onscreenContentManager { return existing }
        let manager = OnscreenContentManager()
        _onscreenContentManager = manager
        return manager
    }

    @MainActor
    static func installOnscreenContentManager(_ manager: OnscreenContentManager) {
        _onscreenContentManager = manager
    }
}

enum AppModelContainer {
    @MainActor
    static func makeShared(bundle: Bundle = .main) -> ModelContainer {
        let schema = Schema([
            PersistedHandbookChapter.self,
            PersistedHandbookSection.self,
            PersistedQuickCard.self,
            PersistedFieldReferenceEntry.self,
            PersistedPracticeProgress.self,
            PersistedSeedContentState.self,
            PersistedInventoryItem.self,
            PersistedDocumentVaultEntry.self,
            PersistedKnowledgePackInstallState.self,
            PersistedChecklistTemplate.self,
            PersistedChecklistTemplateItem.self,
            PersistedChecklistRun.self,
            PersistedChecklistRunItem.self,
            PersistedEmergencyContact.self,
            PersistedNoteRecord.self,
            PersistedWaypoint.self,
            PersistedRecordedTrack.self,
            PersistedRecordedTrackPoint.self,
            PersistedSourceRecord.self,
            PersistedImportedKnowledgeDocument.self,
            PersistedKnowledgeChunk.self,
            PersistedPendingOperation.self,
            PersistedDailyForecast.self,
            PersistedWeatherAlert.self
        ])
        let processInfo = ProcessInfo.processInfo

        do {
            let modelConfiguration: ModelConfiguration
            if processInfo.isRunningUnitTests {
                modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
            } else if processInfo.isRunningUITests {
                let storeDirectory = FileManager.default.temporaryDirectory
                    .appendingPathComponent("OSA-UITests", isDirectory: true)
                try FileManager.default.createDirectory(
                    at: storeDirectory,
                    withIntermediateDirectories: true
                )
                let storeURL = storeDirectory
                    .appendingPathComponent("store-\(processInfo.processIdentifier).sqlite")
                modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
            } else {
                modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false
                )
            }

            let modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            // Skip seed import for unit-test hosts, but allow UI tests to
            // import bundled content into an isolated temporary store.
            guard !processInfo.isRunningUnitTests else {
                return modelContainer
            }

            let contentRepository = SwiftDataContentRepository(modelContext: modelContainer.mainContext)
            let loader = try SeedContentLoader.bundled(in: bundle)
            let importer = SeedContentImporter(
                loader: loader,
                repository: contentRepository
            )

            _ = try importer.importBundledContentIfNeeded()
            _ = BundledKnowledgePackBootstrapper(
                catalogClient: KnowledgePackCatalogClient(bundle: bundle, connectivityService: nil),
                contentRepository: contentRepository,
                installStateRepository: SwiftDataKnowledgePackInstallStateRepository(
                    modelContext: modelContainer.mainContext
                )
            )
            .installBundledPacksIfNeeded()

            return modelContainer
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
