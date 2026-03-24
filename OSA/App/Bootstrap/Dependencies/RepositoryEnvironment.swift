import SwiftUI

private struct HandbookRepositoryKey: EnvironmentKey {
    static let defaultValue: (any HandbookRepository)? = nil
}

private struct QuickCardRepositoryKey: EnvironmentKey {
    static let defaultValue: (any QuickCardRepository)? = nil
}

private struct InventoryRepositoryKey: EnvironmentKey {
    static let defaultValue: (any InventoryRepository)? = nil
}

private struct ChecklistRepositoryKey: EnvironmentKey {
    static let defaultValue: (any ChecklistRepository)? = nil
}

private struct NoteRepositoryKey: EnvironmentKey {
    static let defaultValue: (any NoteRepository)? = nil
}

private struct SearchServiceKey: EnvironmentKey {
    static let defaultValue: (any SearchService)? = nil
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
}
