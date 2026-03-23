import SwiftUI

private struct HandbookRepositoryKey: EnvironmentKey {
    static let defaultValue: (any HandbookRepository)? = nil
}

private struct QuickCardRepositoryKey: EnvironmentKey {
    static let defaultValue: (any QuickCardRepository)? = nil
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
}
