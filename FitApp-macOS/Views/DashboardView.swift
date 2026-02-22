import SwiftData
import SwiftUI

struct DashboardView: View {
    let profile: UserProfile

    @EnvironmentObject private var appState: AppState
    @Query(sort: \WorkoutPlan.weekStartDate, order: .reverse) private var plans: [WorkoutPlan]
    @Query(sort: \WorkoutLog.date, order: .reverse) private var logs: [WorkoutLog]

    @StateObject private var healthKitService = HealthKitService()
    @State private var caloriesToday: Double = 0

    private let weekdayOrder = [
        "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
    ]

    private var currentPlan: WorkoutPlan? {
        plans.first
    }

    private var completedThisWeek: Int {
        let interval = Calendar.current.dateInterval(of: .weekOfYear, for: .now)
        return logs.filter { interval?.contains($0.date) ?? false }.count
    }

    private var streakDays: Int {
        guard !logs.isEmpty else { return 0 }
        let sorted = logs.map(\.date).sorted(by: >)
        var streak = 0
        var dayCursor = Calendar.current.startOfDay(for: .now)

        for date in sorted {
            let logDay = Calendar.current.startOfDay(for: date)
            if logDay == dayCursor {
                streak += 1
                dayCursor = Calendar.current.date(byAdding: .day, value: -1, to: dayCursor) ?? dayCursor
            } else if logDay < dayCursor {
                break
            }
        }
        return streak
    }

    private var nextSessionLabel: String {
        nextSession(from: currentPlan)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Weekly Dashboard")
                    .font(.largeTitle.bold())

                Text(appState.latestTrendInsights?.summary ?? "Based on your recent activity, your next plan is ready to generate.")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    ProgressRingView(
                        title: "Calories",
                        value: min(caloriesToday / 700, 1.0),
                        detail: "\(Int(caloriesToday)) kcal"
                    )
                    ProgressRingView(
                        title: "Completed",
                        value: min(Double(completedThisWeek) / Double(max(profile.daysPerWeek, 1)), 1.0),
                        detail: "\(completedThisWeek)/\(profile.daysPerWeek)"
                    )
                    ProgressRingView(
                        title: "Streak",
                        value: min(Double(streakDays) / 14.0, 1.0),
                        detail: "\(streakDays) days"
                    )
                }

                if let currentPlan {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Week Plan")
                            .font(.title2.bold())

                        ForEach(currentPlan.days) { day in
                            VStack(alignment: .leading, spacing: 10) {
                                Text("\(day.dayOfWeek) · \(day.focus)")
                                    .font(.headline)
                                ForEach(day.exercises) { exercise in
                                    WorkoutCardView(exercise: exercise)
                                }
                            }
                            .padding(12)
                            .background(Color.gray.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }

                TrendChartView(
                    title: "Training Volume (Last 14 sessions)",
                    points: logs.prefix(14).enumerated().map { index, log in
                        TrendPoint(id: index, date: log.date, value: Double(log.completedExercises.count) * 10.0)
                    }
                )
            }
            .padding(20)
        }
        .task {
            do {
                try await healthKitService.requestAuthorization()
                caloriesToday = try await healthKitService.fetchTodayActiveEnergyBurned()
            } catch {
                caloriesToday = 0
            }
            syncQuickStats()
        }
        .onChange(of: caloriesToday) { _ in
            syncQuickStats()
        }
        .onChange(of: logs.count) { _ in
            syncQuickStats()
        }
        .onChange(of: plans.count) { _ in
            syncQuickStats()
        }
    }

    private func syncQuickStats() {
        WatchConnectivityService.shared.sendQuickStats(
            caloriesToday: caloriesToday,
            streak: streakDays,
            nextSession: nextSessionLabel
        )
    }

    private func nextSession(from plan: WorkoutPlan?) -> String {
        guard let plan, !plan.days.isEmpty else {
            return "No workout scheduled"
        }

        let orderedDays = plan.days
            .compactMap { day -> (index: Int, WorkoutDay)? in
                guard let index = weekdayIndex(for: day.dayOfWeek) else {
                    return nil
                }
                return (index, day)
            }
            .sorted { $0.index < $1.index }

        guard !orderedDays.isEmpty else {
            return "No workout scheduled"
        }

        let weekday = Calendar.current.component(.weekday, from: .now)
        let todayIndex = (weekday + 5) % 7

        let next = orderedDays.first { $0.index >= todayIndex } ?? orderedDays.first
        guard let next else {
            return "No workout scheduled"
        }

        return "\(next.1.dayOfWeek) · \(next.1.focus)"
    }

    private func weekdayIndex(for dayName: String) -> Int? {
        weekdayOrder.firstIndex { $0.caseInsensitiveCompare(dayName) == .orderedSame }
    }
}
