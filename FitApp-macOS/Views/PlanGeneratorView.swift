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

    private let client = MCPClient()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Workout Plan Generator")
                    .font(.largeTitle.bold())

                Form {
                    Stepper("Session Length: \(sessionLength) minutes", value: $sessionLength, in: 15 ... 120, step: 5)
                    TextField("Limitations / injuries (optional)", text: $limitations)
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

                if let generatedPlan {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("AI Plan Preview")
                            .font(.title2.bold())
                        Text(generatedPlan.rationale)
                            .foregroundStyle(.secondary)

                        ForEach(generatedPlan.days) { day in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(day.dayOfWeek) · \(day.focus)")
                                    .font(.headline)
                                ForEach(day.exercises) { exercise in
                                    Text("• \(exercise.name) — \(exercise.sets)x\(exercise.reps)")
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

    private func generatePlan() async {
        isGenerating = true
        errorMessage = ""
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
                limitations: limitations.isEmpty ? nil : [limitations]
            )
        )

        do {
            let response = try await client.generatePlan(baseURL: appState.mcpServerURL, request: request)
            generatedPlan = response
            savePlanToStore(response)

            if let firstDay = response.days.first {
                WatchConnectivityService.shared.sendTodayPlan(firstDay)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func savePlanToStore(_ plan: GeneratePlanResponse) {
        let iso = ISO8601DateFormatter()
        let weekStart = iso.date(from: plan.weekStartDate) ?? Date.startOfCurrentWeek()

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

        let model = WorkoutPlan(
            weekStartDate: weekStart,
            days: workoutDays,
            source: "ai",
            summary: plan.rationale
        )

        modelContext.insert(model)
        try? modelContext.save()
    }
}
