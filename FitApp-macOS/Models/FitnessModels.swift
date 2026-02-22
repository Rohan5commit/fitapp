import Foundation
import SwiftData

enum FitnessGoal: String, CaseIterable, Codable, Identifiable {
    case loseWeight = "Lose Weight"
    case buildMuscle = "Build Muscle"
    case endurance = "Endurance"
    case flexibility = "Flexibility"

    var id: String { rawValue }
}

enum FitnessLevel: String, CaseIterable, Codable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var id: String { rawValue }
}

enum ThemeMode: String, CaseIterable, Codable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }
}

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var age: Int
    var fitnessGoalRaw: String
    var fitnessLevelRaw: String
    var preferredWorkoutsRaw: String
    var equipmentRaw: String
    var daysPerWeek: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        age: Int,
        fitnessGoal: FitnessGoal,
        fitnessLevel: FitnessLevel,
        preferredWorkouts: [String],
        equipment: [String],
        daysPerWeek: Int,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.age = age
        fitnessGoalRaw = fitnessGoal.rawValue
        fitnessLevelRaw = fitnessLevel.rawValue
        preferredWorkoutsRaw = preferredWorkouts.joined(separator: ",")
        equipmentRaw = equipment.joined(separator: ",")
        self.daysPerWeek = daysPerWeek
        self.createdAt = createdAt
    }

    var fitnessGoal: FitnessGoal {
        get { FitnessGoal(rawValue: fitnessGoalRaw) ?? .buildMuscle }
        set { fitnessGoalRaw = newValue.rawValue }
    }

    var fitnessLevel: FitnessLevel {
        get { FitnessLevel(rawValue: fitnessLevelRaw) ?? .beginner }
        set { fitnessLevelRaw = newValue.rawValue }
    }

    var preferredWorkouts: [String] {
        get { preferredWorkoutsRaw.split(separator: ",").map { String($0) }.filter { !$0.isEmpty } }
        set { preferredWorkoutsRaw = newValue.joined(separator: ",") }
    }

    var equipment: [String] {
        get { equipmentRaw.split(separator: ",").map { String($0) }.filter { !$0.isEmpty } }
        set { equipmentRaw = newValue.joined(separator: ",") }
    }
}

@Model
final class WorkoutPlan {
    @Attribute(.unique) var id: UUID
    var weekStartDate: Date
    @Relationship(deleteRule: .cascade) var days: [WorkoutDay]
    var source: String
    var summary: String

    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        days: [WorkoutDay],
        source: String = "ai",
        summary: String = ""
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.days = days
        self.source = source
        self.summary = summary
    }
}

@Model
final class WorkoutDay {
    @Attribute(.unique) var id: UUID
    var dayOfWeek: String
    var focus: String
    @Relationship(deleteRule: .cascade) var exercises: [Exercise]

    init(id: UUID = UUID(), dayOfWeek: String, focus: String, exercises: [Exercise]) {
        self.id = id
        self.dayOfWeek = dayOfWeek
        self.focus = focus
        self.exercises = exercises
    }
}

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var sets: Int
    var reps: String
    var duration: Int?
    var restSeconds: Int
    var muscleGroup: String
    var difficulty: String

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

@Model
final class WorkoutLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var planId: UUID?
    @Relationship(deleteRule: .cascade) var completedExercises: [LoggedExercise]
    var notes: String

    init(
        id: UUID = UUID(),
        date: Date,
        planId: UUID? = nil,
        completedExercises: [LoggedExercise],
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.planId = planId
        self.completedExercises = completedExercises
        self.notes = notes
    }
}

@Model
final class LoggedExercise {
    @Attribute(.unique) var id: UUID
    var exerciseId: UUID
    var setsCompleted: Int
    var repsCompleted: Int
    var weightUsed: Double

    init(
        id: UUID = UUID(),
        exerciseId: UUID,
        setsCompleted: Int,
        repsCompleted: Int,
        weightUsed: Double
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.setsCompleted = setsCompleted
        self.repsCompleted = repsCompleted
        self.weightUsed = weightUsed
    }
}

extension Date {
    static func startOfCurrentWeek(calendar: Calendar = .current) -> Date {
        let now = Date()
        let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start
        return start ?? now
    }
}
