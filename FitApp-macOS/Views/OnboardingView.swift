import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var existingProfiles: [UserProfile]

    @State private var name = ""
    @State private var age = 28
    @State private var selectedGoal: FitnessGoal = .buildMuscle
    @State private var selectedLevel: FitnessLevel = .beginner
    @State private var daysPerWeek = 4

    @State private var selectedWorkouts: Set<String> = ["Strength"]
    @State private var selectedEquipment: Set<String> = ["Dumbbells"]

    private let workoutOptions = ["Strength", "HIIT", "Yoga", "Cardio", "Mobility"]
    private let equipmentOptions = ["Bodyweight", "Dumbbells", "Barbell", "Kettlebell", "Bands", "Machine"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Welcome to FitMind")
                .font(.largeTitle.bold())

            Form {
                TextField("Name", text: $name)

                Stepper("Age: \(age)", value: $age, in: 13 ... 100)

                Picker("Fitness Goal", selection: $selectedGoal) {
                    ForEach(FitnessGoal.allCases) { goal in
                        Text(goal.rawValue).tag(goal)
                    }
                }

                Picker("Fitness Level", selection: $selectedLevel) {
                    ForEach(FitnessLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }

                Stepper("Days Per Week: \(daysPerWeek)", value: $daysPerWeek, in: 1 ... 7)

                VStack(alignment: .leading) {
                    Text("Preferred Workouts")
                    HStack {
                        ForEach(workoutOptions, id: \.self) { option in
                            Toggle(option, isOn: binding(for: option, selection: $selectedWorkouts))
                                .toggleStyle(.checkbox)
                        }
                    }
                }

                VStack(alignment: .leading) {
                    Text("Available Equipment")
                    HStack {
                        ForEach(equipmentOptions, id: \.self) { option in
                            Toggle(option, isOn: binding(for: option, selection: $selectedEquipment))
                                .toggleStyle(.checkbox)
                        }
                    }
                }
            }

            Button("Create Profile", action: saveProfile)
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(24)
    }

    private func saveProfile() {
        for profile in existingProfiles {
            modelContext.delete(profile)
        }

        let profile = UserProfile(
            name: name,
            age: age,
            fitnessGoal: selectedGoal,
            fitnessLevel: selectedLevel,
            preferredWorkouts: Array(selectedWorkouts),
            equipment: Array(selectedEquipment),
            daysPerWeek: daysPerWeek
        )
        modelContext.insert(profile)

        try? modelContext.save()
    }

    private func binding(for value: String, selection: Binding<Set<String>>) -> Binding<Bool> {
        Binding(
            get: { selection.wrappedValue.contains(value) },
            set: { isSelected in
                if isSelected {
                    selection.wrappedValue.insert(value)
                } else {
                    selection.wrappedValue.remove(value)
                }
            }
        )
    }
}
