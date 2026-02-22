import SwiftData
import SwiftUI

struct InsightsView: View {
    let profile: UserProfile

    @EnvironmentObject private var appState: AppState
    @Query(sort: \WorkoutLog.date, order: .reverse) private var logs: [WorkoutLog]
    @Query(sort: \WorkoutPlan.weekStartDate, order: .reverse) private var plans: [WorkoutPlan]

    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var adjustments: RecommendAdjustmentsResponse?

    private let client = MCPClient()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("AI Insights")
                    .font(.largeTitle.bold())

                HStack {
                    Button(isLoading ? "Analyzing..." : "Analyze Weekly Trends") {
                        Task { await analyzeTrends() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)

                    Button("Recommend Adjustments") {
                        Task { await requestAdjustments() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading || plans.first == nil)
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                if let insight = appState.latestTrendInsights {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(insight.summary)
                            .font(.headline)

                        Text("Wins")
                            .font(.subheadline.bold())
                        ForEach(insight.wins, id: \.self) { item in Text("• \(item)") }

                        Text("Risks")
                            .font(.subheadline.bold())
                        ForEach(insight.risks, id: \.self) { item in Text("• \(item)") }

                        Text("Recommendations")
                            .font(.subheadline.bold())
                        ForEach(insight.recommendations, id: \.self) { item in Text("• \(item)") }
                    }
                    .padding(14)
                    .background(Color.gray.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let adjustments {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recommended Tweaks")
                            .font(.title3.bold())

                        ForEach(adjustments.adjustments) { item in
                            VStack(alignment: .leading) {
                                Text("\(item.dayOfWeek): \(item.action)")
                                    .font(.headline)
                                Text(item.reason)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text("Deload: \(adjustments.deloadSuggested ? "Yes" : "No")")
                        Text("Reason: \(adjustments.deloadReason)")
                        Text("Next check-in: \(adjustments.nextCheckIn)")
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(Color.gray.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(20)
        }
    }

    private func analyzeTrends() async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        let history: [AnalyzeTrendsRequest.WorkoutHistoryItem] = logs.prefix(21).map { log in
            AnalyzeTrendsRequest.WorkoutHistoryItem(
                date: ISO8601DateFormatter().string(from: log.date),
                exercisesCompleted: log.completedExercises.count,
                totalVolume: log.completedExercises.reduce(0) { $0 + (Double($1.setsCompleted * $1.repsCompleted) * $1.weightUsed) },
                caloriesBurned: nil,
                avgHeartRate: nil,
                perceivedEffort: nil,
                notes: log.notes.isEmpty ? nil : log.notes
            )
        }

        let request = AnalyzeTrendsRequest(
            workoutHistory: history,
            goals: .init(
                primaryGoal: profile.fitnessGoal.rawValue,
                daysPerWeek: profile.daysPerWeek,
                targetMetric: nil,
                notes: nil
            )
        )

        do {
            let response = try await client.analyzeTrends(baseURL: appState.mcpServerURL, request: request)
            appState.latestTrendInsights = response
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func requestAdjustments() async {
        guard let latestPlan = plans.first else { return }

        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        let planResponse = GeneratePlanResponse(
            weekStartDate: ISO8601DateFormatter().string(from: latestPlan.weekStartDate),
            days: latestPlan.days.map { day in
                GeneratePlanResponse.PlanDay(
                    dayOfWeek: day.dayOfWeek,
                    focus: day.focus,
                    exercises: day.exercises.map { exercise in
                        GeneratePlanResponse.PlanExercise(
                            name: exercise.name,
                            sets: exercise.sets,
                            reps: exercise.reps,
                            duration: exercise.duration,
                            restSeconds: exercise.restSeconds,
                            muscleGroup: exercise.muscleGroup,
                            difficulty: exercise.difficulty,
                            notes: nil
                        )
                    }
                )
            },
            rationale: latestPlan.summary,
            recoveryTips: []
        )

        let recentLogs = logs.prefix(7)
        let adherence = min(Double(recentLogs.count) / Double(max(profile.daysPerWeek, 1)) * 100, 100)
        let request = RecommendAdjustmentsRequest(
            recentPerformance: .init(
                adherenceRate: adherence,
                averageEffort: 6.5,
                sorenessLevel: 4.0,
                fatigueLevel: 4.5,
                notes: recentLogs.first?.notes
            ),
            existingPlan: planResponse
        )

        do {
            adjustments = try await client.recommendAdjustments(baseURL: appState.mcpServerURL, request: request)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
