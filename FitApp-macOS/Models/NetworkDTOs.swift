import Foundation

struct AnalyzeTrendsRequest: Codable {
    struct WorkoutHistoryItem: Codable {
        let date: String
        let exercisesCompleted: Int
        let totalVolume: Double?
        let caloriesBurned: Double?
        let avgHeartRate: Double?
        let perceivedEffort: Double?
        let notes: String?
    }

    struct Goals: Codable {
        let primaryGoal: String
        let daysPerWeek: Int
        let targetMetric: String?
        let notes: String?
    }

    let workoutHistory: [WorkoutHistoryItem]
    let goals: Goals
}

struct AnalyzeTrendsResponse: Codable {
    let summary: String
    let wins: [String]
    let risks: [String]
    let recommendations: [String]
    let overtrainingRisk: String
    let plateauRisk: String
}

struct GeneratePlanRequest: Codable {
    struct UserProfileInput: Codable {
        let name: String
        let age: Int
        let fitnessGoal: String
        let fitnessLevel: String
    }

    struct PreferencesInput: Codable {
        let preferredWorkouts: [String]
        let equipment: [String]
        let daysPerWeek: Int
        let sessionLengthMinutes: Int?
        let limitations: [String]?
    }

    let userProfile: UserProfileInput
    let preferences: PreferencesInput
}

struct GeneratePlanResponse: Codable {
    struct PlanExercise: Codable, Identifiable {
        var id = UUID()
        let name: String
        let sets: Int
        let reps: String
        let duration: Int?
        let restSeconds: Int
        let muscleGroup: String
        let difficulty: String
        let notes: String?

        private enum CodingKeys: String, CodingKey {
            case name
            case sets
            case reps
            case duration
            case restSeconds
            case muscleGroup
            case difficulty
            case notes
        }
    }

    struct PlanDay: Codable, Identifiable {
        var id = UUID()
        let dayOfWeek: String
        let focus: String
        let exercises: [PlanExercise]

        private enum CodingKeys: String, CodingKey {
            case dayOfWeek
            case focus
            case exercises
        }
    }

    let weekStartDate: String
    let days: [PlanDay]
    let rationale: String
    let recoveryTips: [String]
}

struct RecommendAdjustmentsRequest: Codable {
    struct RecentPerformance: Codable {
        let adherenceRate: Double
        let averageEffort: Double
        let sorenessLevel: Double
        let fatigueLevel: Double
        let notes: String?
    }

    let recentPerformance: RecentPerformance
    let existingPlan: GeneratePlanResponse
}

struct RecommendAdjustmentsResponse: Codable {
    struct Adjustment: Codable, Identifiable {
        var id = UUID()
        let dayOfWeek: String
        let action: String
        let reason: String

        private enum CodingKeys: String, CodingKey {
            case dayOfWeek
            case action
            case reason
        }
    }

    let adjustments: [Adjustment]
    let deloadSuggested: Bool
    let deloadReason: String
    let nextCheckIn: String
}
