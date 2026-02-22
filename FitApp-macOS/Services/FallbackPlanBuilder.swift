import Foundation

struct FallbackPlanBuilder {
    private static let weekdayOrder = [
        "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
    ]

    static func makePlan(
        profile: UserProfile,
        sessionLengthMinutes: Int,
        limitations: [String]
    ) -> GeneratePlanResponse {
        let daysPerWeek = max(1, min(profile.daysPerWeek, 7))
        let selectedDays = scheduledDays(count: daysPerWeek)
        let focuses = focusSequence(for: profile.fitnessGoal)

        let days: [GeneratePlanResponse.PlanDay] = selectedDays.enumerated().map { offset, dayName in
            let focus = focuses[offset % focuses.count]
            return GeneratePlanResponse.PlanDay(
                dayOfWeek: dayName,
                focus: focus,
                exercises: exercises(
                    for: focus,
                    fitnessLevel: profile.fitnessLevel,
                    preferredWorkouts: profile.preferredWorkouts,
                    sessionLengthMinutes: sessionLengthMinutes
                )
            )
        }

        let iso = ISO8601DateFormatter()
        let startOfWeek = iso.string(from: Date.startOfCurrentWeek())

        let normalizedLimitations = limitations
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var recoveryTips = [
            "Keep 1-2 reps in reserve for compound lifts.",
            "Target 7-9 hours of sleep and hydrate consistently.",
            "Add a 10-minute mobility cool-down after each workout."
        ]

        if !normalizedLimitations.isEmpty {
            recoveryTips.append("Respect limitations: \(normalizedLimitations.joined(separator: ", ")).")
        }

        return GeneratePlanResponse(
            weekStartDate: startOfWeek,
            days: days,
            rationale: "Offline fallback plan generated from your profile while MCP server is unavailable.",
            recoveryTips: recoveryTips
        )
    }

    private static func scheduledDays(count: Int) -> [String] {
        if count == 1 { return ["Monday"] }
        if count == 2 { return ["Monday", "Thursday"] }
        if count == 3 { return ["Monday", "Wednesday", "Friday"] }
        if count == 4 { return ["Monday", "Tuesday", "Thursday", "Saturday"] }
        if count == 5 { return ["Monday", "Tuesday", "Thursday", "Friday", "Saturday"] }
        if count == 6 { return ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"] }
        return weekdayOrder
    }

    private static func focusSequence(for goal: FitnessGoal) -> [String] {
        switch goal {
        case .loseWeight:
            return ["Conditioning", "Strength", "Conditioning", "Core"]
        case .buildMuscle:
            return ["Upper Body", "Lower Body", "Push", "Pull"]
        case .endurance:
            return ["Conditioning", "Tempo", "Intervals", "Recovery"]
        case .flexibility:
            return ["Mobility", "Core Stability", "Flow", "Recovery"]
        }
    }

    private static func exercises(
        for focus: String,
        fitnessLevel: FitnessLevel,
        preferredWorkouts: [String],
        sessionLengthMinutes: Int
    ) -> [GeneratePlanResponse.PlanExercise] {
        let baseSets: Int
        let repRange: String

        switch fitnessLevel {
        case .beginner:
            baseSets = 3
            repRange = "8-12"
        case .intermediate:
            baseSets = 4
            repRange = "6-10"
        case .advanced:
            baseSets = 5
            repRange = "5-8"
        }

        let conditioningDuration = max(12 * 60, min(sessionLengthMinutes * 60 / 2, 25 * 60))
        let mobilityDuration = max(8 * 60, min(sessionLengthMinutes * 60 / 3, 18 * 60))

        if focus.contains("Condition") || focus.contains("Tempo") || focus.contains("Intervals") {
            return [
                .init(
                    name: "Interval Cardio",
                    sets: 6,
                    reps: "45s hard / 75s easy",
                    duration: conditioningDuration,
                    restSeconds: 30,
                    muscleGroup: "Cardio",
                    difficulty: fitnessLevel.rawValue,
                    notes: "Use a treadmill, bike, rower, or brisk outdoor intervals."
                ),
                .init(
                    name: "Plank",
                    sets: 3,
                    reps: "45s",
                    duration: 3 * 45,
                    restSeconds: 45,
                    muscleGroup: "Core",
                    difficulty: fitnessLevel.rawValue,
                    notes: "Prioritize neutral spine and controlled breathing."
                )
            ]
        }

        if focus.contains("Mobility") || focus.contains("Flow") || focus.contains("Recovery") {
            return [
                .init(
                    name: "Dynamic Mobility Flow",
                    sets: 1,
                    reps: "Guided flow",
                    duration: mobilityDuration,
                    restSeconds: 30,
                    muscleGroup: "Mobility",
                    difficulty: "Beginner",
                    notes: "Include hips, thoracic spine, and shoulders."
                ),
                .init(
                    name: "Dead Bug",
                    sets: 3,
                    reps: "8-10/side",
                    duration: nil,
                    restSeconds: 45,
                    muscleGroup: "Core",
                    difficulty: "Beginner",
                    notes: "Slow and controlled tempo."
                )
            ]
        }

        let strengthMain: (name: String, muscleGroup: String)
        let strengthSecondary: (name: String, muscleGroup: String)

        switch focus {
        case "Lower Body":
            strengthMain = ("Goblet Squat", "Legs")
            strengthSecondary = ("Romanian Deadlift", "Posterior Chain")
        case "Push":
            strengthMain = ("Dumbbell Bench Press", "Chest")
            strengthSecondary = ("Overhead Press", "Shoulders")
        case "Pull":
            strengthMain = ("One-Arm Dumbbell Row", "Back")
            strengthSecondary = ("Lat Pulldown or Band Pulldown", "Back")
        default:
            strengthMain = ("Dumbbell Bench Press", "Chest")
            strengthSecondary = ("One-Arm Dumbbell Row", "Back")
        }

        let includesHIIT = preferredWorkouts.contains { $0.caseInsensitiveCompare("HIIT") == .orderedSame }

        var output: [GeneratePlanResponse.PlanExercise] = [
            .init(
                name: strengthMain.name,
                sets: baseSets,
                reps: repRange,
                duration: nil,
                restSeconds: 90,
                muscleGroup: strengthMain.muscleGroup,
                difficulty: fitnessLevel.rawValue,
                notes: "Work at RPE 7-8 and keep technique strict."
            ),
            .init(
                name: strengthSecondary.name,
                sets: max(3, baseSets - 1),
                reps: repRange,
                duration: nil,
                restSeconds: 90,
                muscleGroup: strengthSecondary.muscleGroup,
                difficulty: fitnessLevel.rawValue,
                notes: "Use full range of motion and controlled eccentric."
            ),
            .init(
                name: "Split Squat",
                sets: 3,
                reps: "8-12/side",
                duration: nil,
                restSeconds: 60,
                muscleGroup: "Legs",
                difficulty: fitnessLevel.rawValue,
                notes: "Reduce load if stability is limited."
            )
        ]

        if includesHIIT {
            output.append(
                .init(
                    name: "Finisher Intervals",
                    sets: 4,
                    reps: "20s hard / 40s easy",
                    duration: 4 * 60,
                    restSeconds: 30,
                    muscleGroup: "Cardio",
                    difficulty: fitnessLevel.rawValue,
                    notes: "Optional finisher if recovery is good."
                )
            )
        }

        return output
    }
}
