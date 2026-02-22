import Foundation
import WatchConnectivity

@MainActor
final class WatchSyncService: NSObject, ObservableObject {
    @Published private(set) var todayWorkout: WatchWorkoutDay?
    @Published private(set) var caloriesToday: Double = 0
    @Published private(set) var streak: Int = 0
    @Published private(set) var nextSession: String = "No workout scheduled"
    @Published private(set) var isReachable = false

    private let cache = WorkoutCache()
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    override init() {
        super.init()
        todayWorkout = cache.load()
        activateSession()
    }

    private func activateSession() {
        guard let session else { return }
        session.delegate = self
        session.activate()
        isReachable = session.isReachable
    }

    func sendSetCompletion(
        exerciseName: String,
        setNumber: Int,
        reps: Int,
        elapsedSeconds: Int
    ) {
        guard let session else { return }

        let payload: [String: Any] = [
            "type": "setCompleted",
            "exerciseName": exerciseName,
            "setNumber": setNumber,
            "reps": reps,
            "elapsedSeconds": elapsedSeconds,
            "timestamp": Date().timeIntervalSince1970
        ]

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else {
            try? session.updateApplicationContext(payload)
        }
    }

    private func consumePayload(_ payload: [String: Any]) {
        if let type = payload["type"] as? String, type == "todayPlan", let workout = parseWorkout(from: payload) {
            todayWorkout = workout
            cache.save(workout)
            return
        }

        if let type = payload["type"] as? String, type == "quickStats" {
            if let calories = payload["caloriesToday"] as? Double { caloriesToday = calories }
            if let streak = payload["streak"] as? Int { self.streak = streak }
            if let next = payload["nextSession"] as? String { nextSession = next }
        }
    }

    private func parseWorkout(from payload: [String: Any]) -> WatchWorkoutDay? {
        guard
            let day = payload["dayOfWeek"] as? String,
            let focus = payload["focus"] as? String,
            let exercisesRaw = payload["exercises"] as? [[String: Any]]
        else {
            return nil
        }

        let exercises: [WatchExercise] = exercisesRaw.compactMap { entry in
            guard
                let name = entry["name"] as? String,
                let sets = entry["sets"] as? Int,
                let reps = entry["reps"] as? String,
                let rest = entry["restSeconds"] as? Int,
                let muscleGroup = entry["muscleGroup"] as? String,
                let difficulty = entry["difficulty"] as? String
            else {
                return nil
            }

            return WatchExercise(
                name: name,
                sets: sets,
                reps: reps,
                duration: entry["duration"] as? Int,
                restSeconds: rest,
                muscleGroup: muscleGroup,
                difficulty: difficulty
            )
        }

        return WatchWorkoutDay(dayOfWeek: day, focus: focus, exercises: exercises)
    }
}

extension WatchSyncService: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.consumePayload(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.consumePayload(applicationContext)
        }
    }
}
