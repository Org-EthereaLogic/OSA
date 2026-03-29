import ActivityKit
import Foundation

struct ActiveProtocolActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let completedStepCount: Int
        let totalStepCount: Int
        let completionPercent: Int
        let nextStepLabel: String?
    }

    let runID: UUID
    let protocolTitle: String
}
