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

private struct SupplyTemplateRepositoryKey: EnvironmentKey {
    static let defaultValue: (any SupplyTemplateRepository)? = nil
}

private struct NoteRepositoryKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any NoteRepository)? = nil
}

private struct EmergencyContactRepositoryKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any EmergencyContactRepository)? = nil
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
    static let defaultValue: (any ConnectivityService)? = nil
}

private struct TrustedSourceHTTPClientKey: EnvironmentKey {
    static let defaultValue: (any TrustedSourceHTTPClient)? = nil
}

private struct ImportPipelineKey: EnvironmentKey {
    static let defaultValue: ImportedKnowledgeImportPipeline? = nil
}

private struct InventoryCompletionServiceKey: EnvironmentKey {
    static let defaultValue: (any InventoryCompletionService)? = nil
}

private struct HapticFeedbackServiceKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any HapticFeedbackService)? = nil
}

private struct OnscreenContentManagerKey: EnvironmentKey {
    static let defaultValue: OnscreenContentManager? = nil
}

private struct RSSDiscoveryServiceKey: EnvironmentKey {
    static let defaultValue: (any RSSDiscoveryService)? = nil
}

private struct DiscoveryCoordinatorKey: EnvironmentKey {
    static let defaultValue: KnowledgeDiscoveryCoordinator? = nil
}

private struct WeatherForecastRepositoryKey: EnvironmentKey {
    static let defaultValue: (any WeatherForecastRepository)? = nil
}

private struct WeatherForecastServiceKey: EnvironmentKey {
    static let defaultValue: (any WeatherForecastService)? = nil
}

private struct WeatherAlertServiceKey: EnvironmentKey {
    static let defaultValue: (any WeatherAlertService)? = nil
}

private struct LocationServiceKey: EnvironmentKey {
    static let defaultValue: (any LocationService)? = nil
}

private struct MapAnnotationProviderKey: EnvironmentKey {
    static let defaultValue: (any MapAnnotationProvider)? = nil
}

private struct TileCacheServiceKey: EnvironmentKey {
    static let defaultValue: (any TileCacheService)? = nil
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

    var supplyTemplateRepository: (any SupplyTemplateRepository)? {
        get { self[SupplyTemplateRepositoryKey.self] }
        set { self[SupplyTemplateRepositoryKey.self] = newValue }
    }

    var noteRepository: (any NoteRepository)? {
        get { self[NoteRepositoryKey.self] }
        set { self[NoteRepositoryKey.self] = newValue }
    }

    var emergencyContactRepository: (any EmergencyContactRepository)? {
        get { self[EmergencyContactRepositoryKey.self] }
        set { self[EmergencyContactRepositoryKey.self] = newValue }
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

    var hapticFeedbackService: (any HapticFeedbackService)? {
        get { self[HapticFeedbackServiceKey.self] }
        set { self[HapticFeedbackServiceKey.self] = newValue }
    }

    var onscreenContentManager: OnscreenContentManager? {
        get { self[OnscreenContentManagerKey.self] }
        set { self[OnscreenContentManagerKey.self] = newValue }
    }

    var rssDiscoveryService: (any RSSDiscoveryService)? {
        get { self[RSSDiscoveryServiceKey.self] }
        set { self[RSSDiscoveryServiceKey.self] = newValue }
    }

    var discoveryCoordinator: KnowledgeDiscoveryCoordinator? {
        get { self[DiscoveryCoordinatorKey.self] }
        set { self[DiscoveryCoordinatorKey.self] = newValue }
    }

    var weatherForecastRepository: (any WeatherForecastRepository)? {
        get { self[WeatherForecastRepositoryKey.self] }
        set { self[WeatherForecastRepositoryKey.self] = newValue }
    }

    var weatherForecastService: (any WeatherForecastService)? {
        get { self[WeatherForecastServiceKey.self] }
        set { self[WeatherForecastServiceKey.self] = newValue }
    }

    var weatherAlertService: (any WeatherAlertService)? {
        get { self[WeatherAlertServiceKey.self] }
        set { self[WeatherAlertServiceKey.self] = newValue }
    }

    var locationService: (any LocationService)? {
        get { self[LocationServiceKey.self] }
        set { self[LocationServiceKey.self] = newValue }
    }

    var mapAnnotationProvider: (any MapAnnotationProvider)? {
        get { self[MapAnnotationProviderKey.self] }
        set { self[MapAnnotationProviderKey.self] = newValue }
    }

    var tileCacheService: (any TileCacheService)? {
        get { self[TileCacheServiceKey.self] }
        set { self[TileCacheServiceKey.self] = newValue }
    }
}
