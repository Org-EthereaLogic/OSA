import Foundation

enum ConnectivityState: String {
    case offline = "Offline"
    case onlineConstrained = "Limited"
    case onlineUsable = "Online"
    case syncInProgress = "Refreshing"

    var icon: String {
        switch self {
        case .offline: "wifi.slash"
        case .onlineConstrained: "wifi.exclamationmark"
        case .onlineUsable: "wifi"
        case .syncInProgress: "arrow.triangle.2.circlepath"
        }
    }
}
