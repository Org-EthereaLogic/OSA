import Foundation

struct SearchIndexRebuilder {
    let searchService: any SearchService
    let handbookRepository: any HandbookRepository
    let quickCardRepository: any QuickCardRepository
    let inventoryRepository: any InventoryRepository
    let checklistRepository: any ChecklistRepository
    let noteRepository: any NoteRepository
    let importedKnowledgeRepository: any ImportedKnowledgeRepository

    func rebuild() throws {
        try searchService.indexAllContent()
        try indexHandbookSections()
        try indexQuickCards()
        try indexInventoryItems()
        try indexChecklistTemplates()
        try indexNotes()
        try indexImportedKnowledge()
    }

    private func indexHandbookSections() throws {
        for chapterSummary in try handbookRepository.listChapters() {
            guard let chapter = try handbookRepository.chapter(id: chapterSummary.id) else {
                continue
            }

            for section in chapter.sections {
                try searchService.indexHandbookSection(section, chapterTitle: chapter.title)
            }
        }
    }

    private func indexQuickCards() throws {
        for card in try quickCardRepository.listQuickCards() {
            try searchService.indexQuickCard(card)
        }
    }

    private func indexInventoryItems() throws {
        for item in try inventoryRepository.listItems(includeArchived: false) {
            try searchService.indexInventoryItem(item)
        }
    }

    private func indexChecklistTemplates() throws {
        for templateSummary in try checklistRepository.listTemplates() {
            guard let template = try checklistRepository.template(id: templateSummary.id) else {
                continue
            }

            try searchService.indexChecklistTemplate(template)
        }
    }

    private func indexNotes() throws {
        for note in try noteRepository.listNotes(type: nil) {
            try searchService.indexNote(note)
        }
    }

    private func indexImportedKnowledge() throws {
        var documentByID: [UUID: ImportedKnowledgeDocument] = [:]
        let sourceByID = Dictionary(
            uniqueKeysWithValues: try importedKnowledgeRepository
                .activeSources()
                .map { ($0.id, $0) }
        )

        for chunk in try importedKnowledgeRepository.searchableChunks() {
            let document: ImportedKnowledgeDocument
            if let cached = documentByID[chunk.documentID] {
                document = cached
            } else {
                guard let fetched = try importedKnowledgeRepository.document(id: chunk.documentID) else {
                    continue
                }
                documentByID[chunk.documentID] = fetched
                document = fetched
            }

            guard let source = sourceByID[document.sourceID] else {
                continue
            }

            try searchService.indexImportedChunk(
                chunk,
                sourceTitle: source.sourceTitle,
                publisherDomain: source.publisherDomain
            )
        }
    }
}
