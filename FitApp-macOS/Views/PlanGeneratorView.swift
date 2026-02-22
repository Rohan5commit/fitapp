import SwiftData
import SwiftUI

struct PlanGeneratorView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState

    @State private var sessionLength = 45
    @State private var limitations = ""
    @State private var isGenerating = false
    @State private var generatedPlan: GeneratePlanResponse?
    @State private var errorMessage = ""
    @State private var statusMessage = ""
    @State private var usingFallbackPlan = false

    private let client = MCPClient()

    private let swapLibrary: [String: [String]] = [
        "chest": ["Dumbbell Bench Press", "Incline Push-Up", "Floor Press"],
        "back": ["One-Arm Dumbbell Row", "Chest-Supported Row", "Band Row"],
        "legs": ["Goblet Squat", "Reverse Lunge", "Step-Up"],
        "shoulders": ["Overhead Press", "Arnold Press", "Lateral Raise"],
        "core": ["Plank", "Dead Bug", "Pallof Press"],
        "cardio": ["Interval Cardio", "Row Intervals", "Bike Tempo"]
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Workout Plan Generator")
                    .font(.largeTitle.bold())

                Form {
                    Stepper("Session Length: \(sessionLength) minutes", value: $sessionLength, in: 15 ... 120, step: 5)
                    TextField("Limitations / injuries (optional, comma separated)", text: $limitations)
                }

                HStack {
                    Button(isGenerating ? "Generating..." : "Generate Weekly Plan") {
                        Task { await generatePlan() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isGenerating)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                }

                if usingFallbackPlan {
                    Text("Offline fallback plan is active")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                }

                if let generatedPlan {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Plan Preview")
                            .font(.title2.bold())
                        Text(generatedPlan.rationale)
                            .foregroundStyle(.secondary)

                        ForEach(Array(generatedPlan.days.enumerated()), id: \.offset) { dayIndex, day in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(day.dayOfWeek) · \(day.focus)")
                                    .font(.headline)

                                ForEach(Array(day.exercises.enumerated()), id: \.element.id) { exerciseIndex, exercise in
                                    HStack(alignment: .top) {
                                        Text("• \(exercise.name) — \(exercise.sets)x\(exercise.reps)")
                                        Spacer()
                                        Button("Swap") {
                                            swapExercise(dayIndex: dayIndex, exerciseIndex: exerciseIndex)
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                            }
                            .padding(10)
                            .background(Color.gray.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private var limitationList: [String] {
        limitations
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func generatePlan() async {
        isGenerating = true
        errorMessage = ""
        statusMessage = ""
        defer { isGenerating = false }

        let request = GeneratePlanRequest(
            userProfile: .init(
                name: profile.name,
                age: profile.age,
                fitnessGoal: profile.fitnessGoal.rawValue,
                fitnessLevel: profile.fitnessLevel.rawValue
            ),
            preferences: .init(
                preferredWorkouts: profile.preferredWorkouts,
                equipment: profile.equipment,
                daysPerWeek: profile.daysPerWeek,
                sessionLengthMinutes: sessionLength,
                limitations: limitationList.isEmpty ? nil : limitationList
            )
        )

        do {
            let response = try await client.generatePlan(baseURL: appState.mcpServerURL, request: request)
            generatedPlan = response
            usingFallbackPlan = false
            savePlanToStore(response, source: "ai")
            statusMessage = "AI plan generated successfully."

            if let firstDay = response.days.first {
                WatchConnectivityService.shared.sendTodayPlan(firstDay)
            }
        } catch {
            let fallback = FallbackPlanBuilder.makePlan(
                profile: profile,
                sessionLengthMinutes: sessionLength,
                limitations: limitationList
            )
            generatedPlan = fallback
            usingFallbackPlan = true
            savePlanToStore(fallback, source: "fallback")

            errorMessage = "Could not reach MCP server. Offline fallback plan generated."
            statusMessage = "Fallback reason: \(error.localizedDescription)"

            if let firstDay = fallback.days.first {
                WatchConnectivityService.shared.sendTodayPlan(firstDay)
            }
        }
    }

    private func savePlanToStore(_ plan: GeneratePlanResponse, source: String) {
        let iso = ISO8601DateFormatter()
        let weekStart = iso.date(from: plan.weekStartDate) ?? Date.startOfCurrentWeek()

        let existingPlans = (try? modelContext.fetch(FetchDescriptor<WorkoutPlan>())) ?? []
        for existing in existingPlans where Calendar.current.isDate(existing.weekStartDate, inSameDayAs: weekStart) {
            modelContext.delete(existing)
        }

        let workoutDays = plan.days.map { day in
            WorkoutDay(
                dayOfWeek: day.dayOfWeek,
                focus: day.focus,
                exercises: day.exercises.map { exercise in
                    Exercise(
                        name: exercise.name,
                        sets: exercise.sets,
                        reps: exercise.reps,
                        duration: exercise.duration,
                        restSeconds: exercise.restSeconds,
                        muscleGroup: exercise.muscleGroup,
                        difficulty: exercise.difficulty
                    )
                }
            )
        }

        let summaryPrefix = source == "fallback" ? "Offline fallback. " : ""
        let model = WorkoutPlan(
            weekStartDate: weekStart,
            days: workoutDays,
            source: source,
            summary: summaryPrefix + plan.rationale
        )

        modelContext.insert(model)
        try? modelContext.save()
    }

    private func swapExercise(dayIndex: Int, exerciseIndex: Int) {
        guard let currentPlan = generatedPlan else { return }
        guard currentPlan.days.indices.contains(dayIndex) else { return }

        var updatedDays = currentPlan.days
        let day = updatedDays[dayIndex]
        guard day.exercises.indices.contains(exerciseIndex) else { return }

        var updatedExercises = day.exercises
        let currentExercise = updatedExercises[exerciseIndex]

        let options = swapOptions(for: currentExercise)
        guard !options.isEmpty else { return }

        let currentPosition = options.firstIndex { $0.caseInsensitiveCompare(currentExercise.name) == .orderedSame } ?? -1
        let nextPosition = (currentPosition + 1 + options.count) % options.count
        let nextName = options[nextPosition]

        updatedExercises[exerciseIndex] = GeneratePlanResponse.PlanExercise(
            name: nextName,
            sets: currentExercise.sets,
            reps: currentExercise.reps,
            duration: currentExercise.duration,
            restSeconds: currentExercise.restSeconds,
            muscleGroup: currentExercise.muscleGroup,
            difficulty: currentExercise.difficulty,
            notes: "Swapped from \(currentExercise.name)"
        )

        updatedDays[dayIndex] = GeneratePlanResponse.PlanDay(
            dayOfWeek: day.dayOfWeek,
            focus: day.focus,
            exercises: updatedExercises
        )

        let updatedPlan = GeneratePlanResponse(
            weekStartDate: currentPlan.weekStartDate,
            days: updatedDays,
            rationale: currentPlan.rationale,
            recoveryTips: currentPlan.recoveryTips
        )

        generatedPlan = updatedPlan
        savePlanToStore(updatedPlan, source: usingFallbackPlan ? "fallback" : "ai")
        statusMessage = "Exercise swapped in \(day.dayOfWeek)."
    }

    private func swapOptions(for exercise: GeneratePlanResponse.PlanExercise) -> [String] {
        let muscleGroupKey = exercise.muscleGroup.lowercased()
        if let options = swapLibrary[muscleGroupKey] {
            return options
        }

        let focusKey = exercise.name.lowercased().contains("cardio") ? "cardio" : "core"
        return swapLibrary[focusKey] ?? [exercise.name]
    }
}
