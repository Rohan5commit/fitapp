import Charts
import SwiftData
import SwiftUI

private struct VolumePoint: Identifiable {
    let date: Date
    let volume: Double

    var id: Date { date }
}

private struct MuscleFrequency: Identifiable {
    let name: String
    let count: Int

    var id: String { name }
}

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState

    @Query(sort: \WorkoutLog.date, order: .reverse) private var logs: [WorkoutLog]
    @Query(sort: \WorkoutPlan.weekStartDate, order: .reverse) private var plans: [WorkoutPlan]

    @StateObject private var healthKitService = HealthKitService()

    @State private var logNotes = ""
    @State private var setsCompleted = 3
    @State private var repsCompleted = 10
    @State private var weightUsed = 20.0
    @State private var selectedExerciseID: UUID?
    @State private var isImporting = false
    @State private var statusMessage = ""

    private var exerciseLookup: [UUID: Exercise] {
        var lookup: [UUID: Exercise] = [:]
        for exercise in plans.flatMap(\.days).flatMap(\.exercises) {
            lookup[exercise.id] = exercise
        }
        return lookup
    }

    private var availableExercises: [Exercise] {
        exerciseLookup.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var volumePoints: [VolumePoint] {
        let grouped = Dictionary(grouping: logs) { Calendar.current.startOfDay(for: $0.date) }
        return grouped
            .map { day, dayLogs in
                let dayVolume = dayLogs
                    .flatMap(\.completedExercises)
                    .reduce(0.0) { partial, entry in
                        partial + Double(entry.setsCompleted * entry.repsCompleted) * entry.weightUsed
                    }
                return VolumePoint(date: day, volume: dayVolume)
            }
            .sorted { $0.date < $1.date }
    }

    private var muscleFrequency: [MuscleFrequency] {
        var counts: [String: Int] = [:]

        for log in logs {
            for entry in log.completedExercises {
                let muscle = exerciseLookup[entry.exerciseId]?.muscleGroup ?? "Unmapped"
                counts[muscle, default: 0] += max(entry.setsCompleted, 1)
            }
        }

        return counts
            .map { MuscleFrequency(name: $0.key, count: $0.value) }
            .sorted { left, right in
                if left.count == right.count {
                    return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending
                }
                return left.count > right.count
            }
    }

    private var maxMuscleCount: Int {
        max(muscleFrequency.map(\.count).max() ?? 0, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout History")
                .font(.largeTitle.bold())

            GroupBox("Quick Log") {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Exercise", selection: $selectedExerciseID) {
                        Text("Custom / Untracked").tag(UUID?.none)
                        ForEach(availableExercises, id: \.id) { exercise in
                            Text("\(exercise.name) (\(exercise.muscleGroup))")
                                .tag(exercise.id as UUID?)
                        }
                    }

                    TextField("Notes", text: $logNotes)

                    Stepper("Sets: \(setsCompleted)", value: $setsCompleted, in: 1 ... 10)
                    Stepper("Reps: \(repsCompleted)", value: $repsCompleted, in: 1 ... 30)

                    HStack {
                        Text("Weight")
                        Slider(value: $weightUsed, in: 0 ... 200, step: 2.5)
                        Text("\(Int(weightUsed)) kg")
                    }

                    HStack {
                        Button("Add Workout Log", action: addLog)
                            .buttonStyle(.borderedProminent)

                        Button(isImporting ? "Importing..." : "Import Last 7 Days (HealthKit)") {
                            Task { await importRecentHealthKitWorkouts() }
                        }
                        .buttonStyle(.bordered)
                        .disabled(isImporting)
                    }
                }
                .padding(.top, 6)
            }

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            GroupBox("Volume Over Time") {
                if volumePoints.isEmpty {
                    Text("Add or import workout logs to visualize training volume.")
                        .foregroundStyle(.secondary)
                } else {
                    Chart(volumePoints) { point in
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Volume", point.volume)
                        )
                        .foregroundStyle(.blue.opacity(0.2))

                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Volume", point.volume)
                        )
                        .foregroundStyle(.blue)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Volume", point.volume)
                        )
                        .foregroundStyle(.blue)
                    }
                    .frame(height: 180)
                }
            }

            GroupBox("Muscle Group Frequency") {
                if muscleFrequency.isEmpty {
                    Text("Log exercises linked to a plan to build muscle-group heat data.")
                        .foregroundStyle(.secondary)
                } else {
                    let columns = [GridItem(.adaptive(minimum: 140), spacing: 10)]

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(muscleFrequency) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.subheadline.bold())
                                Text("\(item.count) set logs")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(heatColor(for: item.count))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }
            }

            List {
                ForEach(logs) { log in
                    let entryVolume = log.completedExercises.reduce(0.0) { partial, entry in
                        partial + Double(entry.setsCompleted * entry.repsCompleted) * entry.weightUsed
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(log.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.headline)
                        Text("Exercises logged: \(log.completedExercises.count)")
                            .foregroundStyle(.secondary)
                        Text("Volume: \(Int(entryVolume))")
                            .foregroundStyle(.secondary)
                        if !log.notes.isEmpty {
                            Text(log.notes)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteLogs)
            }
        }
        .padding(20)
        .onAppear {
            syncSelectedExercise()
        }
        .onChange(of: availableExercises.map(\.id)) { _, _ in
            syncSelectedExercise()
        }
    }

    private func addLog() {
        let logged = LoggedExercise(
            exerciseId: selectedExerciseID ?? UUID(),
            setsCompleted: setsCompleted,
            repsCompleted: repsCompleted,
            weightUsed: weightUsed
        )

        let trimmedNotes = logNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        let log = WorkoutLog(
            date: .now,
            completedExercises: [logged],
            notes: trimmedNotes
        )
        modelContext.insert(log)

        do {
            try modelContext.save()
            statusMessage = "Workout log saved."
            logNotes = ""

            if appState.syncLogsToHealthKit {
                let loggedSets = setsCompleted
                let loggedReps = repsCompleted
                Task {
                    await syncLogToHealthKit(
                        logDate: log.date,
                        sets: loggedSets,
                        reps: loggedReps
                    )
                }
            }
        } catch {
            statusMessage = "Could not save log: \(error.localizedDescription)"
        }
    }

    private func importRecentHealthKitWorkouts() async {
        isImporting = true
        defer { isImporting = false }

        do {
            try await healthKitService.requestAuthorization()
            let workouts = try await healthKitService.fetchRecentWorkouts(days: 7)
            var importedCount = 0

            for workout in workouts where !alreadyImported(workout) {
                let minutes = Int(workout.durationMinutes.rounded())
                let calories = Int(workout.energyBurnedKilocalories.rounded())
                let note = "Imported from HealthKit | \(minutes) min | \(calories) kcal"

                let log = WorkoutLog(
                    date: workout.date,
                    completedExercises: [],
                    notes: note
                )
                modelContext.insert(log)
                importedCount += 1
            }

            try modelContext.save()
            statusMessage = importedCount == 0
                ? "No new HealthKit workouts found in the last 7 days."
                : "Imported \(importedCount) workout(s) from HealthKit."
        } catch {
            statusMessage = "HealthKit import failed: \(error.localizedDescription)"
        }
    }

    private func alreadyImported(_ workout: HealthKitService.ImportedWorkout) -> Bool {
        let lowerBound = Calendar.current.date(byAdding: .minute, value: -5, to: workout.date) ?? workout.date
        let upperBound = Calendar.current.date(byAdding: .minute, value: 5, to: workout.date) ?? workout.date

        return logs.contains { log in
            log.notes.hasPrefix("Imported from HealthKit")
                && log.date >= lowerBound
                && log.date <= upperBound
        }
    }

    private func syncSelectedExercise() {
        guard !availableExercises.isEmpty else {
            selectedExerciseID = nil
            return
        }

        if let selectedExerciseID,
           availableExercises.contains(where: { $0.id == selectedExerciseID }) {
            return
        }

        selectedExerciseID = availableExercises.first?.id
    }

    private func deleteLogs(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(logs[index])
        }

        do {
            try modelContext.save()
            statusMessage = "Selected logs deleted."
        } catch {
            statusMessage = "Could not delete logs: \(error.localizedDescription)"
        }
    }

    private func heatColor(for count: Int) -> Color {
        let intensity = Double(count) / Double(maxMuscleCount)
        return Color(red: 0.1, green: 0.55, blue: 0.3)
            .opacity(0.2 + (0.65 * intensity))
    }

    private func syncLogToHealthKit(logDate: Date, sets: Int, reps: Int) async {
        do {
            try await healthKitService.requestAuthorization()

            let estimatedDurationMinutes = max(15, Double(sets * reps) / 6.0)
            let estimatedCalories = max(40, Double(sets * reps) * 0.8)
            let metadata: [String: Any] = [
                "FitMindSource": "HistoryQuickLog"
            ]

            try await healthKitService.saveWorkout(
                startDate: logDate,
                durationMinutes: estimatedDurationMinutes,
                energyBurnedKilocalories: estimatedCalories,
                metadata: metadata
            )

            await MainActor.run {
                statusMessage = "Workout log saved and synced to HealthKit."
            }
        } catch {
            await MainActor.run {
                statusMessage = "Workout log saved, but HealthKit sync failed: \(error.localizedDescription)"
            }
        }
    }
}
