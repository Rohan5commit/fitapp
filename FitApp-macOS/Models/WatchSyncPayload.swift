import Foundation

enum WatchSyncMessageType {
    static let todayPlan = "todayPlan"
    static let setCompleted = "setCompleted"
    static let quickStats = "quickStats"
}

enum WatchSyncPayloadKey {
    static let type = "type"
    static let dayOfWeek = "dayOfWeek"
    static let focus = "focus"
    static let exercises = "exercises"
    static let name = "name"
    static let sets = "sets"
    static let reps = "reps"
    static let duration = "duration"
    static let restSeconds = "restSeconds"
    static let muscleGroup = "muscleGroup"
    static let difficulty = "difficulty"
    static let exerciseName = "exerciseName"
    static let setNumber = "setNumber"
    static let elapsedSeconds = "elapsedSeconds"
    static let timestamp = "timestamp"
    static let caloriesToday = "caloriesToday"
    static let streak = "streak"
    static let nextSession = "nextSession"
}
