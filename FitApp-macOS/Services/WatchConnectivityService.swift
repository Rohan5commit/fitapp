import Foundation
import WatchConnectivity

@MainActor
final class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()

    @Published private(set) var isReachable = false
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var lastReceivedPayload: [String: Any] = [:]

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    override private init() {
        super.init()
        activateSession()
    }

    private func activateSession() {
        guard let session else { return }
        session.delegate = self
        session.activate()
        isReachable = session.isReachable
    }

    func sendTodayPlan(_ plan: GeneratePlanResponse.PlanDay) {
        guard let session else { return }

        let exercisePayloads: [[String: Any]] = plan.exercises.map { exercise in
            var payload: [String: Any] = [
                WatchSyncPayloadKey.name: exercise.name,
                WatchSyncPayloadKey.sets: exercise.sets,
                WatchSyncPayloadKey.reps: exercise.reps,
                WatchSyncPayloadKey.restSeconds: exercise.restSeconds,
                WatchSyncPayloadKey.muscleGroup: exercise.muscleGroup,
                WatchSyncPayloadKey.difficulty: exercise.difficulty
            ]

            if let duration = exercise.duration {
                payload[WatchSyncPayloadKey.duration] = duration
            }

            return payload
        }

        let payload: [String: Any] = [
            WatchSyncPayloadKey.type: WatchSyncMessageType.todayPlan,
            WatchSyncPayloadKey.dayOfWeek: plan.dayOfWeek,
            WatchSyncPayloadKey.focus: plan.focus,
            WatchSyncPayloadKey.exercises: exercisePayloads
        ]

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { _ in }
        } else {
            try? session.updateApplicationContext(payload)
        }
    }
}

extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            self.lastSyncDate = Date()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.lastReceivedPayload = message
            self.lastSyncDate = Date()
            self.isReachable = session.isReachable
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.lastReceivedPayload = applicationContext
            self.lastSyncDate = Date()
            self.isReachable = session.isReachable
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }
}
