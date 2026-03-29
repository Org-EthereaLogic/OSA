import SwiftUI
import WidgetKit

@main
struct OSAWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ReadinessScoreWidget()
        NextExpiringItemWidget()
        RotatingTipWidget()
        EmergencyAccessWidget()
        ActiveProtocolLiveActivity()
    }
}
