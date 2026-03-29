import Foundation

enum EvidenceRanker {
    /// Re-rank search results using deterministic heuristics on top of FTS5 BM25 scores.
    static func rank(
        _ items: [EvidenceItem],
        query: String,
        preferredTags: Set<String> = []
    ) -> [EvidenceItem] {
        let queryWords = Set(
            query.lowercased()
                .components(separatedBy: .alphanumerics.inverted)
                .filter { !$0.isEmpty }
        )

        let scored = items.map { item -> (EvidenceItem, Double) in
            var boost = item.score

            // Boost exact title match
            let titleWords = Set(
                item.title.lowercased()
                    .components(separatedBy: .alphanumerics.inverted)
                    .filter { !$0.isEmpty }
            )
            let titleOverlap = Double(queryWords.intersection(titleWords).count)
            let titleRatio = titleWords.isEmpty ? 0.0 : titleOverlap / Double(titleWords.count)
            boost += titleRatio * 10.0

            // Boost quick cards (emergency-priority content)
            if item.kind == .quickCard {
                boost += 5.0
            }

            // Boost handbook sections (authoritative editorial content)
            if item.kind == .handbookSection {
                boost += 2.0
            }

            // Boost tag matches
            let tagWords = Set(item.tags.flatMap {
                $0.lowercased().components(separatedBy: .alphanumerics.inverted).filter { !$0.isEmpty }
            })
            let tagOverlap = Double(queryWords.intersection(tagWords).count)
            boost += tagOverlap * 3.0

            // Preference tags are a ranking hint only. Untagged universal content remains eligible.
            let preferredTagMatches = preferredTags.intersection(Set(item.tags))
            boost += Double(preferredTagMatches.count) * 4.0

            return (item, boost)
        }

        return scored
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }
}
