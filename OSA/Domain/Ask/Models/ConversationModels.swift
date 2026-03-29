import Foundation

struct RetrievalContext: Equatable, Sendable {
    var followUp: FollowUpContext?
    var preferredTags: Set<String>

    init(
        followUp: FollowUpContext? = nil,
        preferredTags: Set<String> = []
    ) {
        self.followUp = followUp
        self.preferredTags = preferredTags
    }

    var isEmpty: Bool {
        followUp == nil && preferredTags.isEmpty
    }
}

struct FollowUpContext: Equatable, Sendable {
    let previousQuery: String
    let previousAnswerSummary: String
    let previousCitationLabels: [String]
    let previousCitationIDs: [UUID]
}

extension AnswerResult {
    func makeFollowUpContext(summaryCharacterLimit: Int = 220) -> FollowUpContext {
        let summarySource = answerText.isEmpty
            ? evidence.map(\.snippet).joined(separator: " ")
            : answerText
        let sanitizedSummary = summarySource
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return FollowUpContext(
            previousQuery: query,
            previousAnswerSummary: boundedSummary(
                sanitizedSummary,
                characterLimit: summaryCharacterLimit
            ),
            previousCitationLabels: citations.map(\.displayLabel),
            previousCitationIDs: citations.map(\.id)
        )
    }
}

private func boundedSummary(
    _ value: String,
    characterLimit: Int
) -> String {
    guard value.count > characterLimit else { return value }

    let prefix = value.prefix(characterLimit)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    return prefix + "..."
}
