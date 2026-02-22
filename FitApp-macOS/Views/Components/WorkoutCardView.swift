import SwiftUI

struct WorkoutCardView: View {
    let exercise: Exercise

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                Text("\(exercise.sets) sets · \(exercise.reps)")
                    .foregroundStyle(.secondary)
                if let duration = exercise.duration {
                    Text("Duration: \(duration) sec")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(exercise.muscleGroup)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Rest \(exercise.restSeconds)s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(exercise.difficulty)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(10)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
