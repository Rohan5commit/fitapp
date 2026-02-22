import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutLog.date, order: .reverse) private var logs: [WorkoutLog]

    @State private var logNotes = ""
    @State private var setsCompleted = 3
    @State private var repsCompleted = 10
    @State private var weightUsed = 20.0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout History")
                .font(.largeTitle.bold())

            GroupBox("Quick Log") {
                VStack(alignment: .leading, spacing: 10) {
                    TextField("Notes", text: $logNotes)
                    Stepper("Sets: \(setsCompleted)", value: $setsCompleted, in: 1 ... 10)
                    Stepper("Reps: \(repsCompleted)", value: $repsCompleted, in: 1 ... 30)
                    HStack {
                        Text("Weight")
                        Slider(value: $weightUsed, in: 0 ... 200, step: 2.5)
                        Text("\(Int(weightUsed)) kg")
                    }

                    Button("Add Workout Log", action: addLog)
                        .buttonStyle(.borderedProminent)
                }
                .padding(.top, 6)
            }

            List {
                ForEach(logs) { log in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(log.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.headline)
                        Text("Exercises logged: \(log.completedExercises.count)")
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
    }

    private func addLog() {
        let logged = LoggedExercise(
            exerciseId: UUID(),
            setsCompleted: setsCompleted,
            repsCompleted: repsCompleted,
            weightUsed: weightUsed
        )

        let log = WorkoutLog(
            date: .now,
            completedExercises: [logged],
            notes: logNotes
        )
        modelContext.insert(log)
        try? modelContext.save()
        logNotes = ""
    }

    private func deleteLogs(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(logs[index])
        }
        try? modelContext.save()
    }
}
