import Foundation

struct ActiveProtocolActivityPayload: Equatable, Sendable {
    let runID: UUID
    let title: String
    let completedStepCount: Int
    let totalStepCount: Int
    let completionPercent: Int
    let nextStepLabel: String?

    var attributes: ActiveProtocolActivityAttributes {
        ActiveProtocolActivityAttributes(
            runID: runID,
            protocolTitle: title
        )
    }

    var contentState: ActiveProtocolActivityAttributes.ContentState {
        ActiveProtocolActivityAttributes.ContentState(
            completedStepCount: completedStepCount,
            totalStepCount: totalStepCount,
            completionPercent: completionPercent,
            nextStepLabel: nextStepLabel
        )
    }
}

struct ActiveProtocolActivityMapper {
    let stepLabelLimit: Int

    init(stepLabelLimit: Int = SystemSurfaceConfiguration.activityStepLabelLimit) {
        self.stepLabelLimit = stepLabelLimit
    }

    func makePayload(
        from activeRuns: [ChecklistRun],
        templateLookup: (UUID) throws -> ChecklistTemplate?
    ) rethrows -> ActiveProtocolActivityPayload? {
        let eligibleRuns = try activeRuns.compactMap { run -> (ChecklistRun, ChecklistTemplate)? in
            guard run.status == .inProgress, let templateID = run.templateID else {
                return nil
            }
            guard let template = try templateLookup(templateID),
                  template.presentationStyle == .emergencyProtocol else {
                return nil
            }
            return (run, template)
        }

        guard let selected = eligibleRuns.sorted(by: sortEligibleRuns).first else {
            return nil
        }

        let run = selected.0
        let completedStepCount = run.items.filter(\.isComplete).count
        let totalStepCount = run.items.count
        let nextStepLabel = boundedNextStepLabel(from: run)

        return ActiveProtocolActivityPayload(
            runID: run.id,
            title: run.title,
            completedStepCount: completedStepCount,
            totalStepCount: totalStepCount,
            completionPercent: Int(run.completionFraction * 100),
            nextStepLabel: nextStepLabel
        )
    }

    private func sortEligibleRuns(
        _ lhs: (ChecklistRun, ChecklistTemplate),
        _ rhs: (ChecklistRun, ChecklistTemplate)
    ) -> Bool {
        if lhs.0.startedAt != rhs.0.startedAt {
            return lhs.0.startedAt > rhs.0.startedAt
        }
        return lhs.0.title.localizedCaseInsensitiveCompare(rhs.0.title) == .orderedAscending
    }

    private func boundedNextStepLabel(from run: ChecklistRun) -> String? {
        guard let nextItem = run.items
            .sorted(by: { $0.sortOrder < $1.sortOrder })
            .first(where: { !$0.isComplete })
        else {
            return nil
        }

        let trimmed = nextItem.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.count > stepLabelLimit else { return trimmed }
        return String(trimmed.prefix(stepLabelLimit)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }
}
