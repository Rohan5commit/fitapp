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
        let payload: [String: Any] = [
            "type": "todayPlan",
            "dayOfWeek": plan.dayOfWeek,
            "focus": plan.focus,
            "exercises": plan.exercises.map {
                [
                    "name": $0.name,
                    "sets": $0.sets,
                    "reps": $0.reps,
                    "duration": $0.duration as Any,
                    "restSeconds": $0.restSeconds,
                    "muscleGroup": $0.muscleGroup,
                    "difficulty": $0.difficulty
                ]
            }
        ]

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
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

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {}

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.lastReceivedPayload = message
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
