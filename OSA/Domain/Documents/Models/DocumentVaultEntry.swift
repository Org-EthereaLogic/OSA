import Foundation

enum DocumentVaultCategory: String, Codable, CaseIterable, Equatable, Sendable {
    case identity
    case medical
    case insurance
    case property
    case finance
    case emergencyPlan = "emergency-plan"
    case other

    var displayName: String {
        switch self {
        case .identity:
            "Identity"
        case .medical:
            "Medical"
        case .insurance:
            "Insurance"
        case .property:
            "Property"
        case .finance:
            "Finance"
        case .emergencyPlan:
            "Emergency Plan"
        case .other:
            "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .identity:
            "person.text.rectangle"
        case .medical:
            "cross.case.fill"
        case .insurance:
            "checkmark.shield.fill"
        case .property:
            "house.fill"
        case .finance:
            "creditcard.fill"
        case .emergencyPlan:
            "map.fill"
        case .other:
            "doc.text.fill"
        }
    }
}

enum DocumentCaptureSource: String, Codable, CaseIterable, Equatable, Sendable {
    case camera
    case photoLibrary = "photo-library"
    case fileImport = "file-import"

    var displayName: String {
        switch self {
        case .camera:
            "Camera"
        case .photoLibrary:
            "Photo Library"
        case .fileImport:
            "File Import"
        }
    }
}

struct DocumentVaultEntry: Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var category: DocumentVaultCategory
    var captureSource: DocumentCaptureSource
    var encryptedFileIdentifier: String
    var fileExtension: String
    var byteCount: Int
    var ocrSummary: String?
    let createdAt: Date
    var updatedAt: Date
}
