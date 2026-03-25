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
}
