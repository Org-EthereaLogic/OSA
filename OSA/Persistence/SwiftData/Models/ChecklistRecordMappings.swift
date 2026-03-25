import Foundation

// MARK: - ChecklistTemplate Mappings

extension PersistedChecklistTemplate {
    convenience init(from template: ChecklistTemplate) {
        self.init(
            id: template.id,
            slug: template.slug,
            title: template.title,
            category: template.category,
            templateDescription: template.description,
            estimatedMinutes: template.estimatedMinutes,
            tagsJSON: PersistenceValueCoding.encode(template.tags),
            sourceTypeRawValue: template.sourceType.rawValue,
            lastReviewedAt: template.lastReviewedAt
        )
    }

    func update(from template: ChecklistTemplate) {
        slug = template.slug
        title = template.title
        category = template.category
        templateDescription = template.description
        estimatedMinutes = template.estimatedMinutes
        tagsJSON = PersistenceValueCoding.encode(template.tags)
        sourceTypeRawValue = template.sourceType.rawValue
        lastReviewedAt = template.lastReviewedAt
    }

    func toDomain() -> ChecklistTemplate {
        ChecklistTemplate(
            id: id,
            title: title,
            slug: slug,
            category: category,
            description: templateDescription,
            estimatedMinutes: estimatedMinutes,
            tags: PersistenceValueCoding.decodeStrings(from: tagsJSON),
            sourceType: ChecklistSourceType(rawValue: sourceTypeRawValue) ?? .seeded,
            lastReviewedAt: lastReviewedAt,
            items: items
                .sorted {
                    if $0.sortOrder == $1.sortOrder {
                        return $0.text.localizedCaseInsensitiveCompare($1.text) == .orderedAscending
                    }
                    return $0.sortOrder < $1.sortOrder
                }
                .map { $0.toDomain() }
        )
    }
}

// MARK: - ChecklistTemplateItem Mappings

extension PersistedChecklistTemplateItem {
    convenience init(from item: ChecklistTemplateItem, template: PersistedChecklistTemplate? = nil) {
        self.init(
            id: item.id,
            templateID: item.templateID,
            text: item.text,
            detail: item.detail,
            sortOrder: item.sortOrder,
            isOptional: item.isOptional,
            riskLevel: item.riskLevel,
            template: template
        )
    }

    func update(from item: ChecklistTemplateItem) {
        templateID = item.templateID
        text = item.text
        detail = item.detail
        sortOrder = item.sortOrder
        isOptional = item.isOptional
        riskLevel = item.riskLevel
    }

    func toDomain() -> ChecklistTemplateItem {
        ChecklistTemplateItem(
            id: id,
            templateID: templateID,
            text: text,
            detail: detail,
            sortOrder: sortOrder,
            isOptional: isOptional,
            riskLevel: riskLevel
        )
    }
}

// MARK: - ChecklistRun Mappings

extension PersistedChecklistRun {
    convenience init(from run: ChecklistRun) {
        self.init(
            id: run.id,
            templateID: run.templateID,
            title: run.title,
            startedAt: run.startedAt,
            completedAt: run.completedAt,
            statusRawValue: run.status.rawValue,
            contextNote: run.contextNote
        )
    }

    func update(from run: ChecklistRun) {
        templateID = run.templateID
        title = run.title
        completedAt = run.completedAt
        statusRawValue = run.status.rawValue
        contextNote = run.contextNote
    }

    func toDomain() -> ChecklistRun {
        ChecklistRun(
            id: id,
            templateID: templateID,
            title: title,
            startedAt: startedAt,
            completedAt: completedAt,
            status: ChecklistRunStatus(rawValue: statusRawValue) ?? .inProgress,
            contextNote: contextNote,
            items: items
                .sorted { $0.sortOrder < $1.sortOrder }
                .map { $0.toDomain() }
        )
    }
}

// MARK: - ChecklistRunItem Mappings

extension PersistedChecklistRunItem {
    convenience init(from item: ChecklistRunItem, run: PersistedChecklistRun? = nil) {
        self.init(
            id: item.id,
            runID: item.runID,
            templateItemID: item.templateItemID,
            text: item.text,
            isComplete: item.isComplete,
            completedAt: item.completedAt,
            sortOrder: item.sortOrder,
            run: run
        )
    }

    func update(from item: ChecklistRunItem) {
        isComplete = item.isComplete
        completedAt = item.completedAt
        text = item.text
        sortOrder = item.sortOrder
    }

    func toDomain() -> ChecklistRunItem {
        ChecklistRunItem(
            id: id,
            runID: runID,
            templateItemID: templateItemID,
            text: text,
            isComplete: isComplete,
            completedAt: completedAt,
            sortOrder: sortOrder
        )
    }
}
