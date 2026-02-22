import SwiftUI
import WatchKit

struct ActiveWorkoutView: View {
    @EnvironmentObject private var syncService: WatchSyncService
    @StateObject private var heartRateService = HeartRateService()

    @State private var exerciseIndex = 0
    @State private var completedSets = 0
    @State private var reps = 10
    @State private var restRemaining = 0
    @State private var elapsed = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var currentExercise: WatchExercise? {
        guard let workout = syncService.todayWorkout,
              workout.exercises.indices.contains(exerciseIndex) else {
            return nil
        }
        return workout.exercises[exerciseIndex]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if let workout = syncService.todayWorkout {
                    Text(workout.dayOfWeek)
                        .font(.headline)
                    Text(workout.focus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let exercise = currentExercise {
                    Text(exercise.name)
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)

                    Text("Set \(completedSets + 1) / \(exercise.sets)")
                        .font(.caption)

                    Stepper("Reps: \(reps)", value: $reps, in: 1 ... 40)

                    if restRemaining > 0 {
                        Text("Rest: \(restRemaining)s")
                            .font(.title3.monospacedDigit())
                    }

                    Text("Heart rate: \(Int(heartRateService.currentHeartRate)) bpm")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button("Mark Set Done") {
                        markSetDone(exercise: exercise)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Next Exercise") {
                        moveToNextExercise()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Text("No workout loaded")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(8)
        }
        .onAppear {
            Task { await heartRateService.requestAuthorization() }
            heartRateService.start()
        }
        .onDisappear {
            heartRateService.stop()
        }
        .onReceive(timer) { _ in
            elapsed += 1
            guard restRemaining > 0 else { return }
            restRemaining -= 1
            if restRemaining == 0 {
                WKInterfaceDevice.current().play(.notification)
            }
        }
    }

    private func markSetDone(exercise: WatchExercise) {
        completedSets += 1
        restRemaining = exercise.restSeconds

        syncService.sendSetCompletion(
            exerciseName: exercise.name,
            setNumber: completedSets,
            reps: reps,
            elapsedSeconds: elapsed
        )

        if completedSets >= exercise.sets {
            moveToNextExercise()
        }
    }

    private func moveToNextExercise() {
        guard let workout = syncService.todayWorkout else { return }
        completedSets = 0
        reps = 10
        restRemaining = 0
        if exerciseIndex < workout.exercises.count - 1 {
            exerciseIndex += 1
        } else {
            exerciseIndex = 0
        }
    }
}
