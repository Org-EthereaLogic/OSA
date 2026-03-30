import Foundation

enum LocalMediaKind: String, Codable, Equatable, Sendable {
    case inlineSVG = "inline-svg"
    case shortVideo = "short-video"
}

struct LocalMediaAttachment: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let kind: LocalMediaKind
    let bundlePath: String
    let caption: String
    let accessibilityLabel: String
    let transcript: String?
    let preferredHeight: Double?

    init(
        id: String? = nil,
        kind: LocalMediaKind,
        bundlePath: String,
        caption: String,
        accessibilityLabel: String,
        transcript: String? = nil,
        preferredHeight: Double? = nil
    ) {
        self.id = id ?? bundlePath
        self.kind = kind
        self.bundlePath = bundlePath
        self.caption = caption
        self.accessibilityLabel = accessibilityLabel
        self.transcript = transcript
        self.preferredHeight = preferredHeight
    }

    var searchableText: String {
        [caption, accessibilityLabel, transcript]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case bundlePath
        case caption
        case accessibilityLabel
        case transcript
        case preferredHeight
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(LocalMediaKind.self, forKey: .kind)
        let bundlePath = try container.decode(String.self, forKey: .bundlePath)
        let caption = try container.decode(String.self, forKey: .caption)
        let accessibilityLabel = try container.decode(String.self, forKey: .accessibilityLabel)
        let transcript = try container.decodeIfPresent(String.self, forKey: .transcript)
        let preferredHeight = try container.decodeIfPresent(Double.self, forKey: .preferredHeight)
        let id = try container.decodeIfPresent(String.self, forKey: .id)

        self.init(
            id: id,
            kind: kind,
            bundlePath: bundlePath,
            caption: caption,
            accessibilityLabel: accessibilityLabel,
            transcript: transcript,
            preferredHeight: preferredHeight
        )
    }
}

struct QuizDefinition: Codable, Equatable, Sendable {
    let title: String
    let masteryScorePercent: Int
    let questions: [QuizQuestion]

    var questionCount: Int {
        questions.count
    }

    var searchableText: String {
        ([title] + questions.flatMap { question in
            [question.prompt, question.explanation] + question.options.map(\.text)
        })
        .joined(separator: " ")
    }
}

struct QuizQuestion: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let prompt: String
    let options: [QuizOption]
    let correctOptionID: String
    let explanation: String
}

struct QuizOption: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let text: String
}

struct WeeklyDrillMetadata: Codable, Equatable, Sendable {
    let title: String
    let prompt: String
    let badgeLabel: String
}

extension QuizQuestion {
    var correctOption: QuizOption? {
        options.first(where: { $0.id == correctOptionID })
    }
}
