import Foundation

final class SystemSurfaceInventoryRepository: InventoryRepository {
    private let base: any InventoryRepository
    private let widgetSnapshotCoordinator: any WidgetSnapshotRefreshing

    init(
        base: any InventoryRepository,
        widgetSnapshotCoordinator: any WidgetSnapshotRefreshing
    ) {
        self.base = base
        self.widgetSnapshotCoordinator = widgetSnapshotCoordinator
    }

    func listItems(includeArchived: Bool) throws -> [InventoryItem] {
        try base.listItems(includeArchived: includeArchived)
    }

    func item(id: UUID) throws -> InventoryItem? {
        try base.item(id: id)
    }

    func createItem(_ item: InventoryItem) throws {
        try base.createItem(item)
        refreshSnapshot()
    }

    func updateItem(_ item: InventoryItem) throws {
        try base.updateItem(item)
        refreshSnapshot()
    }

    func archiveItem(id: UUID) throws {
        try base.archiveItem(id: id)
        refreshSnapshot()
    }

    func deleteItem(id: UUID) throws {
        try base.deleteItem(id: id)
        refreshSnapshot()
    }

    func itemsExpiringSoon(within days: Int) throws -> [InventoryItem] {
        try base.itemsExpiringSoon(within: days)
    }

    func itemsBelowReorderThreshold() throws -> [InventoryItem] {
        try base.itemsBelowReorderThreshold()
    }

    private func refreshSnapshot() {
        let coordinator = widgetSnapshotCoordinator
        Task { @MainActor in
            await coordinator.refreshSnapshot()
        }
    }
}

final class SystemSurfaceChecklistRepository: ChecklistRepository {
    private let base: any ChecklistRepository
    private let liveActivityCoordinator: ProtocolLiveActivityCoordinator

    init(
        base: any ChecklistRepository,
        liveActivityCoordinator: ProtocolLiveActivityCoordinator
    ) {
        self.base = base
        self.liveActivityCoordinator = liveActivityCoordinator
    }

    func listTemplates() throws -> [ChecklistTemplateSummary] {
        try base.listTemplates()
    }

    func template(slug: String) throws -> ChecklistTemplate? {
        try base.template(slug: slug)
    }

    func template(id: UUID) throws -> ChecklistTemplate? {
        try base.template(id: id)
    }

    func listRuns(status: ChecklistRunStatus?) throws -> [ChecklistRun] {
        try base.listRuns(status: status)
    }

    func run(id: UUID) throws -> ChecklistRun? {
        try base.run(id: id)
    }

    func createRun(_ run: ChecklistRun) throws {
        try base.createRun(run)
        syncLiveActivity()
    }

    func updateRun(_ run: ChecklistRun) throws {
        try base.updateRun(run)
        syncLiveActivity()
    }

    func deleteRun(id: UUID) throws {
        try base.deleteRun(id: id)
        syncLiveActivity()
    }

    func startRun(from templateID: UUID, title: String, contextNote: String?) throws -> ChecklistRun {
        let run = try base.startRun(from: templateID, title: title, contextNote: contextNote)
        syncLiveActivity()
        return run
    }

    func activeRuns() throws -> [ChecklistRun] {
        try base.activeRuns()
    }

    private func syncLiveActivity() {
        let coordinator = liveActivityCoordinator
        Task { @MainActor in
            await coordinator.syncActiveProtocol()
        }
    }
}
