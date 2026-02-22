import Foundation
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

struct SetCompletionEvent {
    let exerciseName: String
    let setNumber: Int
    let reps: Int
    let elapsedSeconds: Int
    let timestamp: Date
}

@MainActor
final class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()

    @Published private(set) var isReachable = false
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var lastReceivedPayload: [String: Any] = [:]
    @Published private(set) var latestSetCompletion: SetCompletionEvent?

#if canImport(WatchConnectivity)
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
#endif

    override private init() {
        super.init()
        activateSession()
    }

    private func activateSession() {
#if canImport(WatchConnectivity)
        guard let session else { return }
        session.delegate = self
        session.activate()
        isReachable = session.isReachable
#else
        isReachable = false
#endif
    }

    func sendTodayPlan(_ plan: GeneratePlanResponse.PlanDay) {
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

        send(payload)
    }

    func sendQuickStats(caloriesToday: Double, streak: Int, nextSession: String) {
        let payload: [String: Any] = [
            WatchSyncPayloadKey.type: WatchSyncMessageType.quickStats,
            WatchSyncPayloadKey.caloriesToday: caloriesToday,
            WatchSyncPayloadKey.streak: streak,
            WatchSyncPayloadKey.nextSession: nextSession
        ]

        send(payload)
    }

    private func send(_ payload: [String: Any]) {
#if canImport(WatchConnectivity)
        guard let session else { return }

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { _ in }
        } else {
            try? session.updateApplicationContext(payload)
        }
#else
        _ = payload
#endif
    }

    private func handleIncomingPayload(_ payload: [String: Any]) {
        lastReceivedPayload = payload
        lastSyncDate = Date()

        guard let type = payload[WatchSyncPayloadKey.type] as? String else {
            return
        }

        guard type == WatchSyncMessageType.setCompleted else {
            return
        }

        guard
            let exerciseName = payload[WatchSyncPayloadKey.exerciseName] as? String,
            let setNumber = intValue(payload[WatchSyncPayloadKey.setNumber]),
            let reps = intValue(payload[WatchSyncPayloadKey.reps]),
            let elapsedSeconds = intValue(payload[WatchSyncPayloadKey.elapsedSeconds])
        else {
            return
        }

        let timestampValue = (payload[WatchSyncPayloadKey.timestamp] as? TimeInterval) ?? Date().timeIntervalSince1970
        let timestamp = Date(timeIntervalSince1970: timestampValue)

        latestSetCompletion = SetCompletionEvent(
            exerciseName: exerciseName,
            setNumber: setNumber,
            reps: reps,
            elapsedSeconds: elapsedSeconds,
            timestamp: timestamp
        )
    }

    private func intValue(_ value: Any?) -> Int? {
        if let intValue = value as? Int {
            return intValue
        }
        if let number = value as? NSNumber {
            return number.intValue
        }
        if let doubleValue = value as? Double {
            return Int(doubleValue)
        }
        return nil
    }
}

#if canImport(WatchConnectivity)
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
            self.handleIncomingPayload(message)
            self.isReachable = session.isReachable
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.handleIncomingPayload(applicationContext)
            self.isReachable = session.isReachable
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }
}
#endif
