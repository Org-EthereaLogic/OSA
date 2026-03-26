import Foundation

/// The structural type of an imported knowledge document.
enum DocumentType: String, Codable, CaseIterable, Equatable, Sendable {
    case article
    case guide
    case reference
    case checklist
}
