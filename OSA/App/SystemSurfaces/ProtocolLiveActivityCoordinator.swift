import ActivityKit
import Foundation

protocol ProtocolLiveActivityClient: AnyObject, Sendable {
    func apply(_ payload: ActiveProtocolActivityPayload?) async
}

final class ActivityKitProtocolLiveActivityClient: ProtocolLiveActivityClient, @unchecked Sendable {
    func apply(_ payload: ActiveProtocolActivityPayload?) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            await endAllActivities()
            return
        }

        let activities = Activity<ActiveProtocolActivityAttributes>.activities

        guard let payload else {
            for activity in activities {
                await activity.end(
                    ActivityContent(state: activity.content.state, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            }
            return
        }

        let matchingActivity = activities.first { $0.attributes.runID == payload.runID }

        if let matchingActivity {
            if matchingActivity.content.state != payload.contentState {
                await matchingActivity.update(
                    ActivityContent(state: payload.contentState, staleDate: nil)
                )
            }

            for activity in activities where activity.id != matchingActivity.id {
                await activity.end(
                    ActivityContent(state: activity.content.state, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            }

            return
        }

        for activity in activities {
            await activity.end(
                ActivityContent(state: activity.content.state, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }

        do {
            _ = try Activity.request(
                attributes: payload.attributes,
                content: ActivityContent(state: payload.contentState, staleDate: nil)
            )
        } catch {
            // Live Activities are best-effort. Leave app behavior unchanged if the request fails.
        }
    }

    private func endAllActivities() async {
        for activity in Activity<ActiveProtocolActivityAttributes>.activities {
            await activity.end(
                ActivityContent(state: activity.content.state, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
    }
}

@MainActor
final class ProtocolLiveActivityCoordinator: Sendable {
    private let checklistRepository: any ChecklistRepository
    private let mapper: ActiveProtocolActivityMapper
    private let client: any ProtocolLiveActivityClient

    init(
        checklistRepository: any ChecklistRepository,
        mapper: ActiveProtocolActivityMapper = ActiveProtocolActivityMapper(),
        client: any ProtocolLiveActivityClient = ActivityKitProtocolLiveActivityClient()
    ) {
        self.checklistRepository = checklistRepository
        self.mapper = mapper
        self.client = client
    }

    func syncActiveProtocol() async {
        do {
            let activeRuns = try checklistRepository.activeRuns()
            let payload = try mapper.makePayload(from: activeRuns) { templateID in
                try checklistRepository.template(id: templateID)
            }
            await client.apply(payload)
        } catch {
            await client.apply(nil)
        }
    }
}
