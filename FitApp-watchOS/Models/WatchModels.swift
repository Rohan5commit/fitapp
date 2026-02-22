import Foundation

struct WatchExercise: Codable, Identifiable {
    let id: UUID
    let name: String
    let sets: Int
    let reps: String
    let duration: Int?
    let restSeconds: Int
    let muscleGroup: String
    let difficulty: String

    init(
        id: UUID = UUID(),
        name: String,
        sets: Int,
        reps: String,
        duration: Int? = nil,
        restSeconds: Int,
        muscleGroup: String,
        difficulty: String
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.duration = duration
        self.restSeconds = restSeconds
        self.muscleGroup = muscleGroup
        self.difficulty = difficulty
    }
}

struct WatchWorkoutDay: Codable {
    let dayOfWeek: String
    let focus: String
    let exercises: [WatchExercise]
}

struct WatchQuickStats: Codable {
    let caloriesToday: Double
    let streak: Int
    let nextSession: String
}
