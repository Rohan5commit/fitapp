import SwiftData
import SwiftUI

private struct WeeklyPlanSlot: Identifiable {
    let dayOfWeek: String
    let focus: String
    let exercises: [Exercise]
    let isToday: Bool

    var id: String { dayOfWeek }
}

struct DashboardView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query(sort: \WorkoutPlan.weekStartDate, order: .reverse) private var plans: [WorkoutPlan]
    @Query(sort: \WorkoutLog.date, order: .reverse) private var logs: [WorkoutLog]

    @ObservedObject private var watchConnectivity = WatchConnectivityService.shared
    @StateObject private var healthKitService = HealthKitService()
    @State private var caloriesToday: Double = 0
    @State private var lastProcessedSetEventTimestamp: TimeInterval = 0

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

    private var todayWeekdayIndex: Int {
        let weekday = Calendar.current.component(.weekday, from: .now)
        return (weekday + 5) % 7
    }

    private var weeklyPlanSlots: [WeeklyPlanSlot] {
        let mappedDays: [String: WorkoutDay] = (currentPlan?.days ?? []).reduce(into: [:]) { partialResult, day in
            partialResult[day.dayOfWeek.lowercased()] = day
        }

        return weekdayOrder.enumerated().map { index, dayName in
            if let planDay = mappedDays[dayName.lowercased()] {
                return WeeklyPlanSlot(
                    dayOfWeek: dayName,
                    focus: planDay.focus,
                    exercises: planDay.exercises,
                    isToday: index == todayWeekdayIndex
                )
            }

            return WeeklyPlanSlot(
                dayOfWeek: dayName,
                focus: "Rest Day",
                exercises: [],
                isToday: index == todayWeekdayIndex
            )
        }
    }

    private var volumeTrendPoints: [TrendPoint] {
        logs
            .prefix(14)
            .enumerated()
            .map { index, log in
                let volume = log.completedExercises.reduce(0.0) { partial, exercise in
                    partial + Double(exercise.setsCompleted * exercise.repsCompleted) * exercise.weightUsed
                }
                return TrendPoint(id: index, date: log.date, value: volume)
            }
            .sorted { $0.date < $1.date }
    }

    private var cardioTrendPoints: [TrendPoint] {
        logs
            .compactMap { log -> TrendPoint? in
                guard let minutes = importedCardioMinutes(from: log.notes) else {
                    return nil
                }
                return TrendPoint(id: log.id.hashValue, date: log.date, value: minutes)
            }
            .sorted { $0.date < $1.date }
    }

    private var restDayTrendPoints: [TrendPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let logDays = Set(logs.map { calendar.startOfDay(for: $0.date) })

        return (0 ..< 14).compactMap { offset -> TrendPoint? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return nil
            }
            let isRestDay = !logDays.contains(date)
            return TrendPoint(
                id: offset,
                date: date,
                value: isRestDay ? 1 : 0
            )
        }
        .sorted { $0.date < $1.date }
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

                if let setEvent = watchConnectivity.latestSetCompletion {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Live Watch Sync")
                            .font(.headline)
                        Text("\(setEvent.exerciseName) · Set \(setEvent.setNumber) · \(setEvent.reps) reps")
                            .font(.subheadline)
                        Text(setEvent.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if let currentPlan {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Week Plan")
                            .font(.title2.bold())

                        Text(currentPlan.summary)
                            .foregroundStyle(.secondary)

                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 220), spacing: 12)],
                            spacing: 12
                        ) {
                            ForEach(weeklyPlanSlots) { slot in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(slot.dayOfWeek)
                                            .font(.headline)
                                        Spacer()
                                        if slot.isToday {
                                            Text("Today")
                                                .font(.caption.bold())
                                                .foregroundStyle(.blue)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(Color.blue.opacity(0.12))
                                                .clipShape(Capsule())
                                        }
                                    }

                                    Text(slot.focus)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    if slot.exercises.isEmpty {
                                        Text("Recovery / rest")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        ForEach(slot.exercises.prefix(2)) { exercise in
                                            Text("• \(exercise.name)")
                                                .font(.caption)
                                        }

                                        if slot.exercises.count > 2 {
                                            Text("+\(slot.exercises.count - 2) more")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.gray.opacity(slot.isToday ? 0.14 : 0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                }

                TrendChartView(
                    title: "Weight Lifted Over Time",
                    points: volumeTrendPoints
                )

                TrendChartView(
                    title: "Cardio Performance (Imported Minutes)",
                    points: cardioTrendPoints
                )

                TrendChartView(
                    title: "Rest Days (1 = Rest, Last 14 Days)",
                    points: restDayTrendPoints
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
            syncWatch()
        }
        .onChange(of: caloriesToday) { _, _ in
            syncWatch()
        }
        .onChange(of: logs.count) { _, _ in
            syncWatch()
        }
        .onChange(of: plans.count) { _, _ in
            syncWatch()
        }
        .onChange(of: watchConnectivity.latestSetCompletion?.timestamp.timeIntervalSince1970 ?? 0) { _, newValue in
            guard newValue > 0 else { return }
            persistLatestSetCompletionIfNeeded()
        }
    }

    private func syncWatch() {
        WatchConnectivityService.shared.sendQuickStats(
            caloriesToday: caloriesToday,
            streak: streakDays,
            nextSession: nextSessionLabel
        )

        guard let todayPlan = currentOrNextPlanDay(from: currentPlan) else {
            return
        }
        WatchConnectivityService.shared.sendTodayPlan(todayPlan)
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

    private func importedCardioMinutes(from notes: String) -> Double? {
        guard notes.hasPrefix("Imported from HealthKit") else {
            return nil
        }

        let parts = notes.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count >= 2 else { return nil }

        let minuteToken = parts[1]
            .split(separator: " ")
            .first
            .flatMap { Double($0) }

        return minuteToken
    }

    private func currentOrNextPlanDay(from plan: WorkoutPlan?) -> GeneratePlanResponse.PlanDay? {
        guard let plan, !plan.days.isEmpty else {
            return nil
        }

        let orderedDays = plan.days
            .compactMap { day -> (index: Int, WorkoutDay)? in
                guard let index = weekdayIndex(for: day.dayOfWeek) else {
                    return nil
                }
                return (index, day)
            }
            .sorted { $0.index < $1.index }

        guard !orderedDays.isEmpty else { return nil }

        let weekday = Calendar.current.component(.weekday, from: .now)
        let todayIndex = (weekday + 5) % 7
        let targetDay = (orderedDays.first { $0.index == todayIndex } ?? orderedDays.first { $0.index > todayIndex })?.1
            ?? orderedDays.first?.1

        guard let targetDay else { return nil }

        let exercises = targetDay.exercises.map { exercise in
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

        return GeneratePlanResponse.PlanDay(
            dayOfWeek: targetDay.dayOfWeek,
            focus: targetDay.focus,
            exercises: exercises
        )
    }

    private func persistLatestSetCompletionIfNeeded() {
        guard let event = watchConnectivity.latestSetCompletion else {
            return
        }

        let eventTimestamp = event.timestamp.timeIntervalSince1970
        guard eventTimestamp > lastProcessedSetEventTimestamp else {
            return
        }
        lastProcessedSetEventTimestamp = eventTimestamp

        let exerciseID = resolveExerciseID(forExerciseName: event.exerciseName) ?? UUID()
        let loggedExercise = LoggedExercise(
            exerciseId: exerciseID,
            setsCompleted: 1,
            repsCompleted: max(event.reps, 1),
            weightUsed: 0
        )

        let today = Calendar.current.startOfDay(for: event.timestamp)
        let existingLog = logs.first { log in
            Calendar.current.isDate(log.date, inSameDayAs: today) && log.notes.hasPrefix("Watch Auto Log")
        }

        if let existingLog {
            existingLog.completedExercises.append(loggedExercise)
            existingLog.notes = "Watch Auto Log · Last update \(event.timestamp.formatted(date: .omitted, time: .shortened))"
        } else {
            let log = WorkoutLog(
                date: event.timestamp,
                completedExercises: [loggedExercise],
                notes: "Watch Auto Log · Started \(event.timestamp.formatted(date: .omitted, time: .shortened))"
            )
            modelContext.insert(log)
        }

        try? modelContext.save()
    }

    private func resolveExerciseID(forExerciseName exerciseName: String) -> UUID? {
        guard let plan = currentPlan else {
            return nil
        }

        let normalized = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return plan.days
            .flatMap(\.exercises)
            .first { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalized }?
            .id
    }
}
