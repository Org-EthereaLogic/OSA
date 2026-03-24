import Foundation

protocol ChecklistRepository {
    // Template queries
    func listTemplates() throws -> [ChecklistTemplateSummary]
    func template(slug: String) throws -> ChecklistTemplate?
    func template(id: UUID) throws -> ChecklistTemplate?

    // Run management
    func listRuns(status: ChecklistRunStatus?) throws -> [ChecklistRun]
    func run(id: UUID) throws -> ChecklistRun?
    func createRun(_ run: ChecklistRun) throws
    func updateRun(_ run: ChecklistRun) throws
    func deleteRun(id: UUID) throws

    // Convenience: start a run from a template
    func startRun(from templateID: UUID, title: String, contextNote: String?) throws -> ChecklistRun

    // Active run queries for Home dashboard
    func activeRuns() throws -> [ChecklistRun]
}
