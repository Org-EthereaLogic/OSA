import Foundation
import SwiftData

final class SwiftDataChecklistRepository: ChecklistRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Template Queries

    func listTemplates() throws -> [ChecklistTemplateSummary] {
        var descriptor = FetchDescriptor<PersistedChecklistTemplate>(
            sortBy: [
                SortDescriptor(\.category),
                SortDescriptor(\.title)
            ]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor)
            .map { $0.toDomain().summaryValue }
    }

    func template(slug: String) throws -> ChecklistTemplate? {
        let descriptor = FetchDescriptor<PersistedChecklistTemplate>()
        return try modelContext.fetch(descriptor)
            .first(where: { $0.slug == slug })?
            .toDomain()
    }

    func template(id: UUID) throws -> ChecklistTemplate? {
        let descriptor = FetchDescriptor<PersistedChecklistTemplate>()
        return try modelContext.fetch(descriptor)
            .first(where: { $0.id == id })?
            .toDomain()
    }

    // MARK: - Run Management

    func listRuns(status: ChecklistRunStatus?) throws -> [ChecklistRun] {
        var descriptor = FetchDescriptor<PersistedChecklistRun>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.includePendingChanges = true

        let results = try modelContext.fetch(descriptor)

        let filtered: [PersistedChecklistRun]
        if let status {
            filtered = results.filter { $0.statusRawValue == status.rawValue }
        } else {
            filtered = results
        }

        return filtered.map { $0.toDomain() }
    }

    func run(id: UUID) throws -> ChecklistRun? {
        let descriptor = FetchDescriptor<PersistedChecklistRun>()
        return try modelContext.fetch(descriptor)
            .first(where: { $0.id == id })?
            .toDomain()
    }

    func createRun(_ run: ChecklistRun) throws {
        let runRecord = PersistedChecklistRun(from: run)
        modelContext.insert(runRecord)

        for item in run.items {
            let itemRecord = PersistedChecklistRunItem(from: item, run: runRecord)
            modelContext.insert(itemRecord)
        }

        try modelContext.save()
    }

    func updateRun(_ run: ChecklistRun) throws {
        let descriptor = FetchDescriptor<PersistedChecklistRun>()
        guard let existing = try modelContext.fetch(descriptor).first(where: { $0.id == run.id }) else {
            return
        }

        existing.update(from: run)

        let existingItemsByID = Dictionary(uniqueKeysWithValues: existing.items.map { ($0.id, $0) })

        for item in run.items {
            if let existingItem = existingItemsByID[item.id] {
                existingItem.update(from: item)
            }
        }

        try modelContext.save()
    }

    func deleteRun(id: UUID) throws {
        let descriptor = FetchDescriptor<PersistedChecklistRun>()
        guard let existing = try modelContext.fetch(descriptor).first(where: { $0.id == id }) else {
            return
        }

        modelContext.delete(existing)
        try modelContext.save()
    }

    func startRun(from templateID: UUID, title: String, contextNote: String?) throws -> ChecklistRun {
        guard let template = try template(id: templateID) else {
            throw ChecklistRepositoryError.templateNotFound(templateID)
        }

        let runID = UUID()
        let now = Date()

        let runItems = template.items.map { templateItem in
            ChecklistRunItem(
                id: UUID(),
                runID: runID,
                templateItemID: templateItem.id,
                text: templateItem.text,
                isComplete: false,
                completedAt: nil,
                sortOrder: templateItem.sortOrder
            )
        }

        let run = ChecklistRun(
            id: runID,
            templateID: templateID,
            title: title,
            startedAt: now,
            completedAt: nil,
            status: .inProgress,
            contextNote: contextNote,
            items: runItems
        )

        try createRun(run)
        return run
    }

    func activeRuns() throws -> [ChecklistRun] {
        try listRuns(status: .inProgress)
    }
}

enum ChecklistRepositoryError: Error {
    case templateNotFound(UUID)
}
