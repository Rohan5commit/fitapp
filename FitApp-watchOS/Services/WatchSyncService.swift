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
            WatchSyncPayloadKey.type: WatchSyncMessageType.setCompleted,
            WatchSyncPayloadKey.exerciseName: exerciseName,
            WatchSyncPayloadKey.setNumber: setNumber,
            WatchSyncPayloadKey.reps: reps,
            WatchSyncPayloadKey.elapsedSeconds: elapsedSeconds,
            WatchSyncPayloadKey.timestamp: Date().timeIntervalSince1970
        ]

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else {
            try? session.updateApplicationContext(payload)
        }
    }

    private func consumePayload(_ payload: [String: Any]) {
        guard let type = payload[WatchSyncPayloadKey.type] as? String else {
            return
        }

        if type == WatchSyncMessageType.todayPlan,
           let workout = parseWorkout(from: payload) {
            todayWorkout = workout
            cache.save(workout)
            return
        }

        if type == WatchSyncMessageType.quickStats {
            if let calories = doubleValue(payload[WatchSyncPayloadKey.caloriesToday]) {
                caloriesToday = calories
            }

            if let streakValue = intValue(payload[WatchSyncPayloadKey.streak]) {
                streak = streakValue
            }

            if let next = payload[WatchSyncPayloadKey.nextSession] as? String {
                nextSession = next
            }
        }
    }

    private func parseWorkout(from payload: [String: Any]) -> WatchWorkoutDay? {
        guard
            let day = payload[WatchSyncPayloadKey.dayOfWeek] as? String,
            let focus = payload[WatchSyncPayloadKey.focus] as? String,
            let exercisesRaw = payload[WatchSyncPayloadKey.exercises] as? [[String: Any]]
        else {
            return nil
        }

        let exercises: [WatchExercise] = exercisesRaw.compactMap { entry in
            guard
                let name = entry[WatchSyncPayloadKey.name] as? String,
                let sets = intValue(entry[WatchSyncPayloadKey.sets]),
                let reps = entry[WatchSyncPayloadKey.reps] as? String,
                let rest = intValue(entry[WatchSyncPayloadKey.restSeconds]),
                let muscleGroup = entry[WatchSyncPayloadKey.muscleGroup] as? String,
                let difficulty = entry[WatchSyncPayloadKey.difficulty] as? String
            else {
                return nil
            }

            return WatchExercise(
                name: name,
                sets: sets,
                reps: reps,
                duration: intValue(entry[WatchSyncPayloadKey.duration]),
                restSeconds: rest,
                muscleGroup: muscleGroup,
                difficulty: difficulty
            )
        }

        return WatchWorkoutDay(dayOfWeek: day, focus: focus, exercises: exercises)
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

    private func doubleValue(_ value: Any?) -> Double? {
        if let doubleValue = value as? Double {
            return doubleValue
        }
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        if let intValue = value as? Int {
            return Double(intValue)
        }
        return nil
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
