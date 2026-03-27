import SwiftUI

private struct HandbookRepositoryKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any HandbookRepository)? = nil
}

private struct QuickCardRepositoryKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any QuickCardRepository)? = nil
}

private struct InventoryRepositoryKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any InventoryRepository)? = nil
}

private struct ChecklistRepositoryKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any ChecklistRepository)? = nil
}

private struct NoteRepositoryKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any NoteRepository)? = nil
}

private struct SearchServiceKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any SearchService)? = nil
}

private struct CapabilityDetectorKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any CapabilityDetector)? = nil
}

private struct RetrievalServiceKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any RetrievalService)? = nil
}

private struct ImportedKnowledgeRepositoryKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any ImportedKnowledgeRepository)? = nil
}

private struct PendingOperationRepositoryKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any PendingOperationRepository)? = nil
}

private struct ConnectivityServiceKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any ConnectivityService)? = nil
}

private struct TrustedSourceHTTPClientKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any TrustedSourceHTTPClient)? = nil
}

private struct ImportPipelineKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: ImportedKnowledgeImportPipeline? = nil
}

private struct InventoryCompletionServiceKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any InventoryCompletionService)? = nil
}

private struct OnscreenContentManagerKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: OnscreenContentManager? = nil
}

private struct DiscoveryCoordinatorKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: KnowledgeDiscoveryCoordinator? = nil
}

extension EnvironmentValues {
    var handbookRepository: (any HandbookRepository)? {
        get { self[HandbookRepositoryKey.self] }
        set { self[HandbookRepositoryKey.self] = newValue }
    }

    var quickCardRepository: (any QuickCardRepository)? {
        get { self[QuickCardRepositoryKey.self] }
        set { self[QuickCardRepositoryKey.self] = newValue }
    }

    var inventoryRepository: (any InventoryRepository)? {
        get { self[InventoryRepositoryKey.self] }
        set { self[InventoryRepositoryKey.self] = newValue }
    }

    var checklistRepository: (any ChecklistRepository)? {
        get { self[ChecklistRepositoryKey.self] }
        set { self[ChecklistRepositoryKey.self] = newValue }
    }

    var noteRepository: (any NoteRepository)? {
        get { self[NoteRepositoryKey.self] }
        set { self[NoteRepositoryKey.self] = newValue }
    }

    var searchService: (any SearchService)? {
        get { self[SearchServiceKey.self] }
        set { self[SearchServiceKey.self] = newValue }
    }

    var capabilityDetector: (any CapabilityDetector)? {
        get { self[CapabilityDetectorKey.self] }
        set { self[CapabilityDetectorKey.self] = newValue }
    }

    var retrievalService: (any RetrievalService)? {
        get { self[RetrievalServiceKey.self] }
        set { self[RetrievalServiceKey.self] = newValue }
    }

    var importedKnowledgeRepository: (any ImportedKnowledgeRepository)? {
        get { self[ImportedKnowledgeRepositoryKey.self] }
        set { self[ImportedKnowledgeRepositoryKey.self] = newValue }
    }

    var pendingOperationRepository: (any PendingOperationRepository)? {
        get { self[PendingOperationRepositoryKey.self] }
        set { self[PendingOperationRepositoryKey.self] = newValue }
    }

    var connectivityService: (any ConnectivityService)? {
        get { self[ConnectivityServiceKey.self] }
        set { self[ConnectivityServiceKey.self] = newValue }
    }

    var trustedSourceHTTPClient: (any TrustedSourceHTTPClient)? {
        get { self[TrustedSourceHTTPClientKey.self] }
        set { self[TrustedSourceHTTPClientKey.self] = newValue }
    }

    var importPipeline: ImportedKnowledgeImportPipeline? {
        get { self[ImportPipelineKey.self] }
        set { self[ImportPipelineKey.self] = newValue }
    }

    var inventoryCompletionService: (any InventoryCompletionService)? {
        get { self[InventoryCompletionServiceKey.self] }
        set { self[InventoryCompletionServiceKey.self] = newValue }
    }

    var onscreenContentManager: OnscreenContentManager? {
        get { self[OnscreenContentManagerKey.self] }
        set { self[OnscreenContentManagerKey.self] = newValue }
    }

    var discoveryCoordinator: KnowledgeDiscoveryCoordinator? {
        get { self[DiscoveryCoordinatorKey.self] }
        set { self[DiscoveryCoordinatorKey.self] = newValue }
    }
}
