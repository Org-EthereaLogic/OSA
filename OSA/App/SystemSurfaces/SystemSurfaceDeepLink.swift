import Foundation

enum SystemSurfaceDeepLink: Equatable, Sendable {
    case emergencyMode
    case quickCard(UUID)
    case checklistRun(UUID)

    init?(url: URL) {
        guard url.scheme?.lowercased() == SystemSurfaceConfiguration.urlScheme else {
            return nil
        }

        let components = url.pathComponents.filter { $0 != "/" }

        switch (url.host?.lowercased(), components) {
        case ("emergency", _):
            self = .emergencyMode
        case ("quick-card", let pathComponents):
            guard let idString = pathComponents.first, let id = UUID(uuidString: idString) else {
                return nil
            }
            self = .quickCard(id)
        case ("checklist-run", let pathComponents):
            guard let idString = pathComponents.first, let id = UUID(uuidString: idString) else {
                return nil
            }
            self = .checklistRun(id)
        default:
            return nil
        }
    }

    var url: URL {
        switch self {
        case .emergencyMode:
            return URL(string: "\(SystemSurfaceConfiguration.urlScheme)://emergency")!
        case .quickCard(let id):
            return URL(string: "\(SystemSurfaceConfiguration.urlScheme)://quick-card/\(id.uuidString.lowercased())")!
        case .checklistRun(let id):
            return URL(string: "\(SystemSurfaceConfiguration.urlScheme)://checklist-run/\(id.uuidString.lowercased())")!
        }
    }
}
